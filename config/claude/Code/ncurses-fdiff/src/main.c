#define _XOPEN_SOURCE 700

#include <curses.h>
#include <dirent.h>
#include <errno.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define STATUS_BUFFER_SIZE 256
#define MAX_FILE_PREVIEW_BYTES 65536
#define MAX_LCS_CELLS 4000000UL

typedef enum {
    NODE_FILE,
    NODE_DIR,
    NODE_OTHER
} NodeType;

typedef enum {
    DIFF_SAME,
    DIFF_ONLY_LEFT,
    DIFF_ONLY_RIGHT,
    DIFF_META_DIFF,
    DIFF_TYPE_MISMATCH,
    DIFF_DIR_CHANGED
} DiffKind;

typedef enum {
    MODE_BROWSER,
    MODE_DIFF
} ViewMode;

typedef struct {
    bool exists;
    NodeType type;
    off_t size;
    time_t mtime_sec;
    long mtime_nsec;
    mode_t mode;
} FileMeta;

typedef struct {
    char *relative_path;
    char *name;
    int depth;
    DiffKind kind;
    FileMeta left;
    FileMeta right;
} DiffEntry;

typedef struct {
    DiffEntry *items;
    size_t len;
    size_t cap;
} EntryList;

typedef struct {
    char **items;
    size_t len;
    size_t cap;
} NameList;

typedef struct {
    size_t same_count;
    size_t only_left_count;
    size_t only_right_count;
    size_t meta_diff_count;
    size_t type_mismatch_count;
    size_t dir_changed_count;
} DiffCounts;

typedef struct {
    char **items;
    size_t len;
    size_t cap;
} StringList;

typedef struct {
    size_t *items;
    size_t len;
    size_t cap;
} IndexList;

typedef struct {
    bool loaded;
    bool available;
    off_t total_size;
    size_t file_count;
    size_t dir_count;
} TreeStats;

typedef struct {
    char *left_text;
    char *right_text;
    size_t left_line_no;
    size_t right_line_no;
    bool left_changed;
    bool right_changed;
} DiffLinePair;

typedef struct {
    DiffLinePair *items;
    size_t len;
    size_t cap;
    size_t entry_index;
    size_t scroll;
    bool loaded;
} SideBySideDiff;

typedef struct {
    char *base_left_root;
    char *base_right_root;
    char *left_root;
    char *right_root;
    char *current_prefix;
    EntryList entries;
    TreeStats *left_stats;
    TreeStats *right_stats;
    bool *expanded;
    bool expansion_enabled;
    bool recursive_size_enabled;
    bool child_counts_enabled;
    size_t expanded_len;
    IndexList visible_entries;
    DiffCounts counts;
    size_t selected_visible;
    size_t scroll;
    ViewMode mode;
    SideBySideDiff diff_view;
    char status[STATUS_BUFFER_SIZE];
} AppState;

typedef struct {
    char *data;
    size_t len;
    bool binary;
    bool truncated;
} FileBuffer;

static void rescan(AppState *app);

typedef struct {
    char kind;
    size_t left_index;
    size_t right_index;
} DiffOp;

typedef struct {
    DiffOp *items;
    size_t len;
    size_t cap;
} DiffOpList;

static void die(const char *message) {
    endwin();
    fprintf(stderr, "%s\n", message);
    exit(1);
}

static void *xmalloc(size_t size) {
    void *ptr = malloc(size);
    if (ptr == NULL) {
        die("Out of memory");
    }
    return ptr;
}

static void *xrealloc(void *ptr, size_t size) {
    void *result = realloc(ptr, size);
    if (result == NULL) {
        die("Out of memory");
    }
    return result;
}

static char *xstrdup(const char *value) {
    size_t len = strlen(value) + 1;
    char *copy = xmalloc(len);
    memcpy(copy, value, len);
    return copy;
}

static char *xstrndup(const char *value, size_t len) {
    char *copy = xmalloc(len + 1);
    memcpy(copy, value, len);
    copy[len] = '\0';
    return copy;
}

static void draw_text_clipped(int row, int col, int width, const char *fmt, ...) {
    if (width <= 0) {
        return;
    }

    char buffer[2048];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    mvprintw(row, col, "%.*s", width, buffer);
}

static char *path_join(const char *base, const char *suffix) {
    if (suffix == NULL || suffix[0] == '\0') {
        return xstrdup(base);
    }

    size_t base_len = strlen(base);
    size_t suffix_len = strlen(suffix);
    bool needs_sep = base_len > 0 && base[base_len - 1] != '/';
    size_t total = base_len + suffix_len + (needs_sep ? 2 : 1);
    char *joined = xmalloc(total);

    if (needs_sep) {
        snprintf(joined, total, "%s/%s", base, suffix);
    } else {
        snprintf(joined, total, "%s%s", base, suffix);
    }

    return joined;
}

static char *relative_join(const char *base, const char *name) {
    if (base == NULL || base[0] == '\0') {
        return xstrdup(name);
    }

    size_t base_len = strlen(base);
    size_t name_len = strlen(name);
    size_t total = base_len + name_len + 2;
    char *joined = xmalloc(total);
    snprintf(joined, total, "%s/%s", base, name);
    return joined;
}

static const char *base_name(const char *path) {
    const char *slash = strrchr(path, '/');
    return slash == NULL ? path : slash + 1;
}

static const char *display_path(const char *path) {
    return (path == NULL || path[0] == '\0') ? "." : path;
}

static void entry_list_push(EntryList *list, DiffEntry entry) {
    if (list->len == list->cap) {
        size_t new_cap = list->cap == 0 ? 128 : list->cap * 2;
        list->items = xrealloc(list->items, new_cap * sizeof(*list->items));
        list->cap = new_cap;
    }
    list->items[list->len++] = entry;
}

static void name_list_push(NameList *list, char *name) {
    if (list->len == list->cap) {
        size_t new_cap = list->cap == 0 ? 32 : list->cap * 2;
        list->items = xrealloc(list->items, new_cap * sizeof(*list->items));
        list->cap = new_cap;
    }
    list->items[list->len++] = name;
}

static int name_compare(const void *lhs, const void *rhs) {
    const char *const *left = lhs;
    const char *const *right = rhs;
    return strcasecmp(*left, *right);
}

static void name_list_sort(NameList *list) {
    qsort(list->items, list->len, sizeof(*list->items), name_compare);
}

static void name_list_free(NameList *list) {
    for (size_t i = 0; i < list->len; i++) {
        free(list->items[i]);
    }
    free(list->items);
    memset(list, 0, sizeof(*list));
}

static void string_list_push(StringList *list, char *value) {
    if (list->len == list->cap) {
        size_t new_cap = list->cap == 0 ? 32 : list->cap * 2;
        list->items = xrealloc(list->items, new_cap * sizeof(*list->items));
        list->cap = new_cap;
    }
    list->items[list->len++] = value;
}

static void string_list_free(StringList *list) {
    for (size_t i = 0; i < list->len; i++) {
        free(list->items[i]);
    }
    free(list->items);
    memset(list, 0, sizeof(*list));
}

static void diff_op_list_push(DiffOpList *list, DiffOp op) {
    if (list->len == list->cap) {
        size_t new_cap = list->cap == 0 ? 64 : list->cap * 2;
        list->items = xrealloc(list->items, new_cap * sizeof(*list->items));
        list->cap = new_cap;
    }
    list->items[list->len++] = op;
}

static void diff_line_push(SideBySideDiff *view, DiffLinePair pair) {
    if (view->len == view->cap) {
        size_t new_cap = view->cap == 0 ? 128 : view->cap * 2;
        view->items = xrealloc(view->items, new_cap * sizeof(*view->items));
        view->cap = new_cap;
    }
    view->items[view->len++] = pair;
}

static void index_list_push(IndexList *list, size_t value) {
    if (list->len == list->cap) {
        size_t new_cap = list->cap == 0 ? 64 : list->cap * 2;
        list->items = xrealloc(list->items, new_cap * sizeof(*list->items));
        list->cap = new_cap;
    }
    list->items[list->len++] = value;
}

static void index_list_reset(IndexList *list) {
    list->len = 0;
}

static void index_list_free(IndexList *list) {
    free(list->items);
    memset(list, 0, sizeof(*list));
}

static NodeType node_type_from_mode(mode_t mode) {
    if (S_ISDIR(mode)) {
        return NODE_DIR;
    }
    if (S_ISREG(mode)) {
        return NODE_FILE;
    }
    return NODE_OTHER;
}

static struct timespec stat_mtime(const struct stat *st) {
#if defined(__APPLE__)
    struct timespec value = {st->st_mtime, st->st_mtimensec};
    return value;
#elif defined(_POSIX_VERSION)
    return st->st_mtim;
#else
    struct timespec value = {st->st_mtime, 0};
    return value;
#endif
}

static FileMeta read_meta(const char *path) {
    struct stat st;
    FileMeta meta;
    memset(&meta, 0, sizeof(meta));

    if (lstat(path, &st) != 0) {
        return meta;
    }

    struct timespec mtime = stat_mtime(&st);
    meta.exists = true;
    meta.type = node_type_from_mode(st.st_mode);
    meta.size = st.st_size;
    meta.mtime_sec = mtime.tv_sec;
    meta.mtime_nsec = mtime.tv_nsec;
    meta.mode = st.st_mode;
    return meta;
}

static bool file_meta_equal(const FileMeta *left, const FileMeta *right) {
    return left->type == right->type &&
           left->size == right->size &&
           left->mtime_sec == right->mtime_sec &&
           left->mtime_nsec == right->mtime_nsec &&
           ((left->mode & 07777) == (right->mode & 07777));
}

static void counts_add(DiffCounts *counts, DiffKind kind) {
    switch (kind) {
        case DIFF_SAME:
            counts->same_count++;
            break;
        case DIFF_ONLY_LEFT:
            counts->only_left_count++;
            break;
        case DIFF_ONLY_RIGHT:
            counts->only_right_count++;
            break;
        case DIFF_META_DIFF:
            counts->meta_diff_count++;
            break;
        case DIFF_TYPE_MISMATCH:
            counts->type_mismatch_count++;
            break;
        case DIFF_DIR_CHANGED:
            counts->dir_changed_count++;
            break;
    }
}

static void add_entry(AppState *app, const char *relative_path, int depth, DiffKind kind, FileMeta left, FileMeta right) {
    DiffEntry entry;
    entry.relative_path = xstrdup(relative_path);
    entry.name = xstrdup(base_name(relative_path));
    entry.depth = depth;
    entry.kind = kind;
    entry.left = left;
    entry.right = right;
    entry_list_push(&app->entries, entry);
    counts_add(&app->counts, kind);
}

static NameList read_dir_names(const char *path) {
    NameList names;
    memset(&names, 0, sizeof(names));

    DIR *dir = opendir(path);
    if (dir == NULL) {
        return names;
    }

    for (;;) {
        struct dirent *ent = readdir(dir);
        if (ent == NULL) {
            break;
        }
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0) {
            continue;
        }
        name_list_push(&names, xstrdup(ent->d_name));
    }

    closedir(dir);
    name_list_sort(&names);
    return names;
}

static void add_missing_subtree(AppState *app, const char *root_path, const char *relative_path, int depth, bool is_left) {
    char *absolute = path_join(root_path, relative_path);
    FileMeta meta = read_meta(absolute);
    FileMeta missing;
    memset(&missing, 0, sizeof(missing));

    add_entry(app, relative_path, depth, is_left ? DIFF_ONLY_LEFT : DIFF_ONLY_RIGHT, is_left ? meta : missing, is_left ? missing : meta);

    if (meta.exists && meta.type == NODE_DIR) {
        NameList names = read_dir_names(absolute);
        for (size_t i = 0; i < names.len; i++) {
            char *child_rel = relative_join(relative_path, names.items[i]);
            add_missing_subtree(app, root_path, child_rel, depth + 1, is_left);
            free(child_rel);
        }
        name_list_free(&names);
    }

    free(absolute);
}

static bool compare_recursive(AppState *app, const char *relative_path, int depth) {
    char *left_abs = path_join(app->left_root, relative_path);
    char *right_abs = path_join(app->right_root, relative_path);
    FileMeta left = read_meta(left_abs);
    FileMeta right = read_meta(right_abs);
    bool changed = false;

    if (!left.exists && !right.exists) {
        free(left_abs);
        free(right_abs);
        return false;
    }

    if (!left.exists) {
        add_missing_subtree(app, app->right_root, relative_path, depth, false);
        free(left_abs);
        free(right_abs);
        return true;
    }

    if (!right.exists) {
        add_missing_subtree(app, app->left_root, relative_path, depth, true);
        free(left_abs);
        free(right_abs);
        return true;
    }

    if (left.type != right.type) {
        add_entry(app, relative_path, depth, DIFF_TYPE_MISMATCH, left, right);
        free(left_abs);
        free(right_abs);
        return true;
    }

    if (left.type == NODE_DIR) {
        size_t index = app->entries.len;
        add_entry(app, relative_path, depth, DIFF_SAME, left, right);

        NameList left_names = read_dir_names(left_abs);
        NameList right_names = read_dir_names(right_abs);
        size_t li = 0;
        size_t ri = 0;

        while (li < left_names.len || ri < right_names.len) {
            if (li < left_names.len && ri < right_names.len) {
                int cmp = strcasecmp(left_names.items[li], right_names.items[ri]);
                if (cmp == 0) {
                    char *child_rel = relative_join(relative_path, left_names.items[li]);
                    if (compare_recursive(app, child_rel, depth + 1)) {
                        changed = true;
                    }
                    free(child_rel);
                    li++;
                    ri++;
                } else if (cmp < 0) {
                    char *child_rel = relative_join(relative_path, left_names.items[li]);
                    add_missing_subtree(app, app->left_root, child_rel, depth + 1, true);
                    changed = true;
                    free(child_rel);
                    li++;
                } else {
                    char *child_rel = relative_join(relative_path, right_names.items[ri]);
                    add_missing_subtree(app, app->right_root, child_rel, depth + 1, false);
                    changed = true;
                    free(child_rel);
                    ri++;
                }
            } else if (li < left_names.len) {
                char *child_rel = relative_join(relative_path, left_names.items[li]);
                add_missing_subtree(app, app->left_root, child_rel, depth + 1, true);
                changed = true;
                free(child_rel);
                li++;
            } else {
                char *child_rel = relative_join(relative_path, right_names.items[ri]);
                add_missing_subtree(app, app->right_root, child_rel, depth + 1, false);
                changed = true;
                free(child_rel);
                ri++;
            }
        }

        if (!file_meta_equal(&left, &right)) {
            changed = true;
        }

        if (changed) {
            app->entries.items[index].kind = DIFF_DIR_CHANGED;
            app->counts.same_count--;
            app->counts.dir_changed_count++;
        }

        name_list_free(&left_names);
        name_list_free(&right_names);
        free(left_abs);
        free(right_abs);
        return changed;
    }

    DiffKind kind = file_meta_equal(&left, &right) ? DIFF_SAME : DIFF_META_DIFF;
    add_entry(app, relative_path, depth, kind, left, right);
    free(left_abs);
    free(right_abs);
    return kind != DIFF_SAME;
}

static void free_entries(EntryList *list) {
    for (size_t i = 0; i < list->len; i++) {
        free(list->items[i].relative_path);
        free(list->items[i].name);
    }
    free(list->items);
    memset(list, 0, sizeof(*list));
}

static void free_tree_stats(TreeStats **stats) {
    free(*stats);
    *stats = NULL;
}

static void update_context_roots(AppState *app, const char *prefix) {
    char *new_left = path_join(app->base_left_root, prefix);
    char *new_right = path_join(app->base_right_root, prefix);
    char *new_prefix = xstrdup(prefix);

    free(app->left_root);
    free(app->right_root);
    free(app->current_prefix);
    app->left_root = new_left;
    app->right_root = new_right;
    app->current_prefix = new_prefix;
}

static bool entry_is_directory(const DiffEntry *entry) {
    return (entry->left.exists && entry->left.type == NODE_DIR) ||
           (entry->right.exists && entry->right.type == NODE_DIR);
}

static int max_entry_depth(const AppState *app) {
    int max_depth = 0;
    for (size_t i = 0; i < app->entries.len; i++) {
        if (app->entries.items[i].depth > max_depth) {
            max_depth = app->entries.items[i].depth;
        }
    }
    return max_depth;
}

static void rebuild_visible_entries(AppState *app) {
    index_list_reset(&app->visible_entries);
    if (app->entries.len == 0) {
        app->selected_visible = 0;
        app->scroll = 0;
        return;
    }

    int max_depth = max_entry_depth(app);
    bool *visible_at_depth = xmalloc((size_t)(max_depth + 1) * sizeof(*visible_at_depth));
    bool *expanded_at_depth = xmalloc((size_t)(max_depth + 1) * sizeof(*expanded_at_depth));
    memset(visible_at_depth, 0, (size_t)(max_depth + 1) * sizeof(*visible_at_depth));
    memset(expanded_at_depth, 0, (size_t)(max_depth + 1) * sizeof(*expanded_at_depth));

    for (size_t i = 0; i < app->entries.len; i++) {
        const DiffEntry *entry = &app->entries.items[i];
        bool visible = entry->depth == 0 || (visible_at_depth[entry->depth - 1] && expanded_at_depth[entry->depth - 1]);
        visible_at_depth[entry->depth] = visible;
        expanded_at_depth[entry->depth] = entry_is_directory(entry) && app->expanded[i];
        if (visible) {
            index_list_push(&app->visible_entries, i);
        }
    }

    free(visible_at_depth);
    free(expanded_at_depth);

    if (app->visible_entries.len == 0) {
        app->selected_visible = 0;
        app->scroll = 0;
        return;
    }

    if (app->selected_visible >= app->visible_entries.len) {
        app->selected_visible = app->visible_entries.len - 1;
    }
    if (app->scroll > app->selected_visible) {
        app->scroll = app->selected_visible;
    }
}

static ssize_t visible_position_for_entry(const AppState *app, size_t entry_index) {
    for (size_t i = 0; i < app->visible_entries.len; i++) {
        if (app->visible_entries.items[i] == entry_index) {
            return (ssize_t)i;
        }
    }
    return -1;
}

static size_t selected_entry_index(const AppState *app) {
    if (app->visible_entries.len == 0 || app->selected_visible >= app->visible_entries.len) {
        return SIZE_MAX;
    }
    return app->visible_entries.items[app->selected_visible];
}

static ssize_t parent_directory_index(const AppState *app, size_t entry_index) {
    if (entry_index >= app->entries.len) {
        return -1;
    }

    int depth = app->entries.items[entry_index].depth;
    if (depth == 0) {
        return -1;
    }

    for (ssize_t i = (ssize_t)entry_index - 1; i >= 0; i--) {
        if (app->entries.items[i].depth == depth - 1 && entry_is_directory(&app->entries.items[i])) {
            return i;
        }
    }
    return -1;
}

static void set_selected_entry(AppState *app, size_t entry_index) {
    ssize_t visible_pos = visible_position_for_entry(app, entry_index);
    if (visible_pos >= 0) {
        app->selected_visible = (size_t)visible_pos;
    }
}

static void select_entry_by_relative_path(AppState *app, const char *relative_path) {
    if (relative_path == NULL) {
        return;
    }

    for (size_t i = 0; i < app->entries.len; i++) {
        if (strcmp(app->entries.items[i].relative_path, relative_path) == 0) {
            set_selected_entry(app, i);
            return;
        }
    }
}

static void enter_selected_directory(AppState *app) {
    size_t entry_index = selected_entry_index(app);
    if (entry_index == SIZE_MAX) {
        return;
    }

    const DiffEntry *entry = &app->entries.items[entry_index];
    if (!entry_is_directory(entry)) {
        return;
    }

    char *new_prefix = app->current_prefix[0] == '\0'
        ? xstrdup(entry->relative_path)
        : relative_join(app->current_prefix, entry->relative_path);
    update_context_roots(app, new_prefix);
    free(new_prefix);
    rescan(app);
}

static void enter_parent_directory(AppState *app) {
    if (app->current_prefix == NULL || app->current_prefix[0] == '\0') {
        return;
    }

    char *child_name = xstrdup(base_name(app->current_prefix));
    const char *slash = strrchr(app->current_prefix, '/');
    char *parent_prefix = slash == NULL ? xstrdup("") : xstrndup(app->current_prefix, (size_t)(slash - app->current_prefix));
    update_context_roots(app, parent_prefix);
    free(parent_prefix);
    rescan(app);
    select_entry_by_relative_path(app, child_name);
    free(child_name);
}

static void toggle_selected_directory(AppState *app, bool expand_only, bool collapse_only) {
    size_t entry_index = selected_entry_index(app);
    if (entry_index == SIZE_MAX) {
        return;
    }

    if (entry_is_directory(&app->entries.items[entry_index])) {
        bool current = app->expanded[entry_index];
        if (expand_only && current) {
            return;
        }
        if (collapse_only && !current) {
            ssize_t parent_index = parent_directory_index(app, entry_index);
            if (parent_index >= 0) {
                set_selected_entry(app, (size_t)parent_index);
                entry_index = (size_t)parent_index;
                if (!app->expanded[entry_index]) {
                    return;
                }
            } else {
                return;
            }
        }

        app->expanded[entry_index] = expand_only ? true : collapse_only ? false : !current;
        rebuild_visible_entries(app);
        set_selected_entry(app, entry_index);
        return;
    }

    if (collapse_only) {
        ssize_t parent_index = parent_directory_index(app, entry_index);
        if (parent_index >= 0) {
            set_selected_entry(app, (size_t)parent_index);
        }
    }
}

static void reset_diff_view(AppState *app) {
    for (size_t i = 0; i < app->diff_view.len; i++) {
        free(app->diff_view.items[i].left_text);
        free(app->diff_view.items[i].right_text);
    }
    free(app->diff_view.items);
    memset(&app->diff_view, 0, sizeof(app->diff_view));
}

static void rescan(AppState *app) {
    free_entries(&app->entries);
    free_tree_stats(&app->left_stats);
    free_tree_stats(&app->right_stats);
    free(app->expanded);
    app->expanded = NULL;
    app->expanded_len = 0;
    index_list_reset(&app->visible_entries);
    memset(&app->counts, 0, sizeof(app->counts));
    app->selected_visible = 0;
    app->scroll = 0;
    app->mode = MODE_BROWSER;
    reset_diff_view(app);

    NameList left_names = read_dir_names(app->left_root);
    NameList right_names = read_dir_names(app->right_root);
    size_t li = 0;
    size_t ri = 0;

    while (li < left_names.len || ri < right_names.len) {
        if (li < left_names.len && ri < right_names.len) {
            int cmp = strcasecmp(left_names.items[li], right_names.items[ri]);
            if (cmp == 0) {
                compare_recursive(app, left_names.items[li], 0);
                li++;
                ri++;
            } else if (cmp < 0) {
                add_missing_subtree(app, app->left_root, left_names.items[li], 0, true);
                li++;
            } else {
                add_missing_subtree(app, app->right_root, right_names.items[ri], 0, false);
                ri++;
            }
        } else if (li < left_names.len) {
            add_missing_subtree(app, app->left_root, left_names.items[li], 0, true);
            li++;
        } else {
            add_missing_subtree(app, app->right_root, right_names.items[ri], 0, false);
            ri++;
        }
    }

    name_list_free(&left_names);
    name_list_free(&right_names);
    app->expanded_len = app->entries.len;
    app->expanded = calloc(app->expanded_len, sizeof(*app->expanded));
    if (app->expanded == NULL && app->expanded_len > 0) {
        die("Out of memory");
    }
    if (app->entries.len > 0) {
        app->left_stats = calloc(app->entries.len, sizeof(*app->left_stats));
        app->right_stats = calloc(app->entries.len, sizeof(*app->right_stats));
        if (app->left_stats == NULL || app->right_stats == NULL) {
            die("Out of memory");
        }
    }
    rebuild_visible_entries(app);
    snprintf(app->status, sizeof(app->status), "Scanned %zu entries in %s using metadata-first comparison",
             app->entries.len,
             display_path(app->current_prefix));
}

static bool entry_has_text_diff(const DiffEntry *entry) {
    return entry->left.exists &&
           entry->right.exists &&
           entry->left.type == NODE_FILE &&
           entry->right.type == NODE_FILE &&
           entry->kind != DIFF_SAME;
}

static const char *type_label(NodeType type) {
    switch (type) {
        case NODE_DIR:
            return "dir";
        case NODE_OTHER:
            return "other";
        case NODE_FILE:
        default:
            return "file";
    }
}

static void format_mode(mode_t mode, char *buffer, size_t size) {
    snprintf(buffer, size, "%04o", mode & 07777);
}

static void format_time_value(time_t sec, long nsec, char *buffer, size_t size) {
    struct tm tm_value;
    localtime_r(&sec, &tm_value);
    strftime(buffer, size, "%Y-%m-%d %H:%M:%S", &tm_value);
    size_t used = strlen(buffer);
    snprintf(buffer + used, size - used, ".%09ld", nsec);
}

static void format_size_value(off_t size, char *buffer, size_t size_bytes) {
    static const char *units[] = {"B", "KiB", "MiB", "GiB", "TiB"};
    double value = (double)size;
    size_t unit_index = 0;
    while (value >= 1024.0 && unit_index + 1 < sizeof(units) / sizeof(units[0])) {
        value /= 1024.0;
        unit_index++;
    }

    if (unit_index == 0) {
        snprintf(buffer, size_bytes, "%lld %s", (long long)size, units[unit_index]);
    } else {
        snprintf(buffer, size_bytes, "%.1f %s", value, units[unit_index]);
    }
}

static int compare_mtime(const FileMeta *left, const FileMeta *right) {
    if (!left->exists || !right->exists) {
        return 0;
    }
    if (left->mtime_sec < right->mtime_sec) {
        return -1;
    }
    if (left->mtime_sec > right->mtime_sec) {
        return 1;
    }
    if (left->mtime_nsec < right->mtime_nsec) {
        return -1;
    }
    if (left->mtime_nsec > right->mtime_nsec) {
        return 1;
    }
    return 0;
}

static TreeStats compute_tree_stats(const char *path, FileMeta meta) {
    TreeStats stats;
    memset(&stats, 0, sizeof(stats));
    stats.loaded = true;
    stats.available = meta.exists;
    if (!meta.exists) {
        return stats;
    }

    if (meta.type == NODE_FILE) {
        stats.total_size = meta.size;
        return stats;
    }

    if (meta.type != NODE_DIR) {
        stats.total_size = meta.size;
        return stats;
    }

    NameList names = read_dir_names(path);
    for (size_t i = 0; i < names.len; i++) {
        char *child_path = path_join(path, names.items[i]);
        FileMeta child_meta = read_meta(child_path);
        if (child_meta.exists) {
            if (child_meta.type == NODE_DIR) {
                TreeStats child_stats = compute_tree_stats(child_path, child_meta);
                stats.dir_count++;
                stats.dir_count += child_stats.dir_count;
                stats.file_count += child_stats.file_count;
                stats.total_size += child_stats.total_size;
            } else {
                stats.file_count++;
                stats.total_size += child_meta.size;
            }
        }
        free(child_path);
    }
    name_list_free(&names);
    return stats;
}

static TreeStats *stats_cache_for_side(AppState *app, bool is_left) {
    return is_left ? app->left_stats : app->right_stats;
}

static const TreeStats *ensure_entry_stats(AppState *app, size_t entry_index, bool is_left) {
    if (entry_index >= app->entries.len) {
        return NULL;
    }

    TreeStats *cache = stats_cache_for_side(app, is_left);
    if (cache == NULL) {
        return NULL;
    }

    TreeStats *stats = &cache[entry_index];
    if (stats->loaded) {
        return stats;
    }

    const DiffEntry *entry = &app->entries.items[entry_index];
    FileMeta meta = is_left ? entry->left : entry->right;
    const char *root = is_left ? app->left_root : app->right_root;
    char *path = path_join(root, entry->relative_path);
    *stats = compute_tree_stats(path, meta);
    free(path);
    return stats;
}

static void format_entry_size(AppState *app,
                              const DiffEntry *entry,
                              size_t entry_index,
                              bool is_left,
                              char *buffer,
                              size_t buffer_size) {
    FileMeta meta = is_left ? entry->left : entry->right;
    if (!meta.exists) {
        snprintf(buffer, buffer_size, "-");
        return;
    }

    off_t size_value = meta.size;
    if (app->recursive_size_enabled) {
        const TreeStats *stats = ensure_entry_stats(app, entry_index, is_left);
        if (stats != NULL && stats->available) {
            size_value = stats->total_size;
        }
    }
    format_size_value(size_value, buffer, buffer_size);
}

static void format_entry_counts(AppState *app,
                                const DiffEntry *entry,
                                size_t entry_index,
                                bool is_left,
                                char *buffer,
                                size_t buffer_size) {
    buffer[0] = '\0';
    if (!app->child_counts_enabled) {
        return;
    }

    FileMeta meta = is_left ? entry->left : entry->right;
    if (!meta.exists || meta.type != NODE_DIR) {
        return;
    }

    const TreeStats *stats = ensure_entry_stats(app, entry_index, is_left);
    if (stats == NULL || !stats->available) {
        return;
    }

    snprintf(buffer, buffer_size, "  %zuf %zud", stats->file_count, stats->dir_count);
}

static void draw_mtime_status_line(int row,
                                   int col,
                                   int width,
                                   const char *time_text,
                                   bool is_newer,
                                   bool is_older) {
    if (width <= 0) {
        return;
    }

    move(row, col);
    for (int i = 0; i < width; i++) {
        addch(' ');
    }

    char prefix[256];
    snprintf(prefix, sizeof(prefix), "mtime: %s", time_text);
    mvprintw(row, col, "%.*s", width, prefix);

    const char *suffix = NULL;
    int color = 0;
    if (is_newer) {
        suffix = " (new)";
        color = 3;
    } else if (is_older) {
        suffix = " (old)";
        color = 2;
    }

    if (suffix == NULL) {
        return;
    }

    int used = (int)strlen(prefix);
    int suffix_space = width - used;
    if (suffix_space <= 0) {
        return;
    }

    attron(COLOR_PAIR(color));
    mvprintw(row, col + used, "%.*s", suffix_space, suffix);
    attroff(COLOR_PAIR(color));
}

static int diff_color(DiffKind kind) {
    switch (kind) {
        case DIFF_ONLY_LEFT:
            return 3;
        case DIFF_ONLY_RIGHT:
            return 3;
        case DIFF_META_DIFF:
            return 4;
        case DIFF_TYPE_MISMATCH:
            return 5;
        case DIFF_DIR_CHANGED:
            return 4;
        case DIFF_SAME:
        default:
            return 1;
    }
}

static int browser_cell_color(const DiffEntry *entry, bool is_left) {
    if (is_left && !entry->left.exists) {
        return 2;
    }
    if (!is_left && !entry->right.exists) {
        return 2;
    }
    if (entry->kind == DIFF_ONLY_LEFT) {
        return is_left ? 3 : 2;
    }
    if (entry->kind == DIFF_ONLY_RIGHT) {
        return is_left ? 2 : 3;
    }
    return diff_color(entry->kind);
}

static char browser_marker(const DiffEntry *entry, bool is_left) {
    bool exists = is_left ? entry->left.exists : entry->right.exists;
    bool other_exists = is_left ? entry->right.exists : entry->left.exists;
    if (!exists) {
        return '-';
    }
    if (!other_exists) {
        return '+';
    }
    if (entry->kind == DIFF_TYPE_MISMATCH) {
        return '~';
    }
    if (entry->kind != DIFF_SAME) {
        return '!';
    }
    return ' ';
}

static char *entry_display_name(const DiffEntry *entry, bool is_left) {
    const FileMeta *meta = is_left ? &entry->left : &entry->right;
    const char *label = meta->exists ? entry->name : "(missing)";
    const char *suffix = meta->exists && meta->type == NODE_DIR ? "/" : "";
    size_t total = (size_t)(entry->depth * 2) + strlen(label) + strlen(suffix) + 1;
    char *value = xmalloc(total + 1);
    snprintf(value, total + 1, "%*s%s%s", entry->depth * 2, "", label, suffix);
    return value;
}

static void draw_browser_entry_cell(AppState *app,
                                    int row,
                                    int col,
                                    int width,
                                    const DiffEntry *entry,
                                    size_t entry_index,
                                    bool is_left,
                                    char marker,
                                    const char *twisty,
                                    const char *name) {
    if (app->recursive_size_enabled) {
        char size_text[32];
        format_entry_size(app, entry, entry_index, is_left, size_text, sizeof(size_text));
        draw_text_clipped(row, col, width, "%9s %c%s %s", size_text, marker, twisty, name);
    } else {
        draw_text_clipped(row, col, width, "%c%s %s", marker, twisty, name);
    }
}

static void draw_header(const AppState *app, int cols) {
    attron(A_BOLD);
    draw_text_clipped(0, 0, cols, "ncdiff  %s", app->status);
    attroff(A_BOLD);
    mvhline(1, 0, ACS_HLINE, cols);
}

static void draw_browser(AppState *app, int rows, int cols) {
    int separator = cols / 2;
    int left_width = separator;
    int right_col = separator + 1;
    int right_width = cols - right_col;
    int list_top = 5;
    int list_height = rows - list_top - 4;
    if (list_height < 1) {
        list_height = 1;
    }

    draw_text_clipped(2, 0, left_width, "Left:  %s", app->left_root);
    draw_text_clipped(2, right_col, right_width, "Right: %s", app->right_root);
    draw_text_clipped(3, 0, cols, "Legend: - missing  + one-sided  ! changed  ~ type mismatch  Enter/Right/l open  Left/h/backspace up  e expand  s size  c counts");
    draw_text_clipped(4, 0, left_width, "Left Tree");
    draw_text_clipped(4, right_col, right_width, "Right Tree");
    mvaddch(2, separator, ACS_VLINE);
    mvaddch(3, separator, ACS_VLINE);
    mvaddch(4, separator, ACS_VLINE);
    for (int row = list_top; row < rows - 3; row++) {
        mvaddch(row, separator, ACS_VLINE);
    }

    for (int row = list_top; row < list_top + list_height; row++) {
        move(row, 0);
        clrtoeol();
        mvaddch(row, separator, ACS_VLINE);
    }

    for (int i = 0; i < list_height; i++) {
        size_t visible_index = app->scroll + (size_t)i;
        int row = list_top + i;
        if (visible_index >= app->visible_entries.len) {
            continue;
        }

        size_t index = app->visible_entries.items[visible_index];
        const DiffEntry *entry = &app->entries.items[index];
        char *left_name = entry_display_name(entry, true);
        char *right_name = entry_display_name(entry, false);
        char left_marker = browser_marker(entry, true);
        char right_marker = browser_marker(entry, false);
        bool is_dir = entry_is_directory(entry);
        const char *twisty = is_dir ? (app->expanded[index] ? "v" : ">") : " ";

        if (visible_index == app->selected_visible) {
            attron(A_REVERSE);
        }

        attron(COLOR_PAIR(browser_cell_color(entry, true)));
        draw_browser_entry_cell(app, row, 0, left_width, entry, index, true, left_marker, twisty, left_name);
        attroff(COLOR_PAIR(browser_cell_color(entry, true)));

        attron(COLOR_PAIR(browser_cell_color(entry, false)));
        draw_browser_entry_cell(app, row, right_col, right_width, entry, index, false, right_marker, twisty, right_name);
        attroff(COLOR_PAIR(browser_cell_color(entry, false)));

        if (visible_index == app->selected_visible) {
            attroff(A_REVERSE);
        }

        free(left_name);
        free(right_name);
    }

    size_t entry_index = selected_entry_index(app);
    if (entry_index != SIZE_MAX) {
        const DiffEntry *entry = &app->entries.items[entry_index];
        char left_mode[16] = "-";
        char right_mode[16] = "-";
        char left_time[64] = "-";
        char right_time[64] = "-";
        char left_size[32] = "-";
        char right_size[32] = "-";
        char left_counts[64] = "";
        char right_counts[64] = "";
        if (entry->left.exists) {
            format_mode(entry->left.mode, left_mode, sizeof(left_mode));
            format_time_value(entry->left.mtime_sec, entry->left.mtime_nsec, left_time, sizeof(left_time));
        }
        if (entry->right.exists) {
            format_mode(entry->right.mode, right_mode, sizeof(right_mode));
            format_time_value(entry->right.mtime_sec, entry->right.mtime_nsec, right_time, sizeof(right_time));
        }
        format_entry_size(app, entry, entry_index, true, left_size, sizeof(left_size));
        format_entry_size(app, entry, entry_index, false, right_size, sizeof(right_size));
        format_entry_counts(app, entry, entry_index, true, left_counts, sizeof(left_counts));
        format_entry_counts(app, entry, entry_index, false, right_counts, sizeof(right_counts));
        int time_cmp = compare_mtime(&entry->left, &entry->right);

        draw_text_clipped(rows - 3, 0, cols, "Context: %s    Selected: %s    Expand:%s  Size:%s  Counts:%s    Keys: Up/Down/PgUp/PgDn/j/k move  Enter/Right/l open  Left/h/backspace up  r rescan  q quit",
                          display_path(app->current_prefix),
                          entry->relative_path,
                          app->expansion_enabled ? "on" : "off",
                          app->recursive_size_enabled ? "tree" : "entry",
                          app->child_counts_enabled ? "on" : "off");
        draw_text_clipped(rows - 2, 0, left_width, "Left:  %s  sz=%s  m=%s%s",
                          entry->left.exists ? type_label(entry->left.type) : "missing",
                          left_size,
                          left_mode,
                          left_counts);
        draw_text_clipped(rows - 2, right_col, right_width, "Right: %s  sz=%s  m=%s%s",
                          entry->right.exists ? type_label(entry->right.type) : "missing",
                          right_size,
                          right_mode,
                          right_counts);
        draw_mtime_status_line(rows - 1, 0, left_width, left_time, time_cmp > 0, time_cmp < 0);
        draw_mtime_status_line(rows - 1, right_col, right_width, right_time, time_cmp < 0, time_cmp > 0);
    } else {
        draw_text_clipped(rows - 3, 0, cols, "Context: %s    Expand:%s  Size:%s  Counts:%s    Keys: Up/Down/PgUp/PgDn/j/k move  Enter/Right/l open  Left/h/backspace up  r rescan  q quit",
                          display_path(app->current_prefix),
                          app->expansion_enabled ? "on" : "off",
                          app->recursive_size_enabled ? "tree" : "entry",
                          app->child_counts_enabled ? "on" : "off");
    }
}

static FileBuffer read_file_buffer(const char *path) {
    FileBuffer result;
    memset(&result, 0, sizeof(result));

    FILE *file = fopen(path, "rb");
    if (file == NULL) {
        return result;
    }

    size_t cap = 4096;
    result.data = xmalloc(cap);

    for (;;) {
        if (result.len == MAX_FILE_PREVIEW_BYTES) {
            result.truncated = true;
            break;
        }
        if (result.len == cap) {
            cap *= 2;
            if (cap > MAX_FILE_PREVIEW_BYTES + 1) {
                cap = MAX_FILE_PREVIEW_BYTES + 1;
            }
            result.data = xrealloc(result.data, cap);
        }

        size_t remaining = cap - result.len;
        size_t read_count = fread(result.data + result.len, 1, remaining, file);
        result.len += read_count;
        if (read_count < remaining) {
            if (ferror(file)) {
                free(result.data);
                memset(&result, 0, sizeof(result));
            }
            break;
        }
    }

    fclose(file);

    if (result.data == NULL) {
        return result;
    }

    if (result.len == cap) {
        result.data = xrealloc(result.data, result.len + 1);
    }
    result.data[result.len] = '\0';

    for (size_t i = 0; i < result.len; i++) {
        if (result.data[i] == '\0') {
            result.binary = true;
            break;
        }
    }

    return result;
}

static StringList split_lines(const char *data) {
    StringList lines;
    memset(&lines, 0, sizeof(lines));

    const char *cursor = data;
    while (*cursor != '\0') {
        const char *line_end = strchr(cursor, '\n');
        if (line_end == NULL) {
            string_list_push(&lines, xstrdup(cursor));
            return lines;
        }
        string_list_push(&lines, xstrndup(cursor, (size_t)(line_end - cursor)));
        cursor = line_end + 1;
    }

    if (lines.len == 0) {
        string_list_push(&lines, xstrdup(""));
    }

    return lines;
}

static void add_pair_copy(SideBySideDiff *view,
                          const char *left_text,
                          const char *right_text,
                          size_t left_line_no,
                          size_t right_line_no,
                          bool left_changed,
                          bool right_changed) {
    DiffLinePair pair;
    pair.left_text = left_text == NULL ? NULL : xstrdup(left_text);
    pair.right_text = right_text == NULL ? NULL : xstrdup(right_text);
    pair.left_line_no = left_line_no;
    pair.right_line_no = right_line_no;
    pair.left_changed = left_changed;
    pair.right_changed = right_changed;
    diff_line_push(view, pair);
}

static void build_naive_pairs(SideBySideDiff *view, const StringList *left, const StringList *right) {
    size_t max_len = left->len > right->len ? left->len : right->len;
    for (size_t i = 0; i < max_len; i++) {
        const char *left_text = i < left->len ? left->items[i] : NULL;
        const char *right_text = i < right->len ? right->items[i] : NULL;
        bool same = left_text != NULL && right_text != NULL && strcmp(left_text, right_text) == 0;
        add_pair_copy(view,
                      left_text,
                      right_text,
                      left_text == NULL ? 0 : i + 1,
                      right_text == NULL ? 0 : i + 1,
                      !same && left_text != NULL,
                      !same && right_text != NULL);
    }
}

static void build_lcs_pairs(SideBySideDiff *view, const StringList *left, const StringList *right) {
    size_t rows = left->len + 1;
    size_t cols = right->len + 1;
    size_t cell_count = rows * cols;
    int *dp = calloc(cell_count, sizeof(*dp));
    if (dp == NULL) {
        build_naive_pairs(view, left, right);
        return;
    }

    for (size_t i = left->len; i > 0; i--) {
        for (size_t j = right->len; j > 0; j--) {
            size_t li = i - 1;
            size_t rj = j - 1;
            size_t index = li * cols + rj;
            if (strcmp(left->items[li], right->items[rj]) == 0) {
                dp[index] = 1 + dp[(li + 1) * cols + (rj + 1)];
            } else {
                int skip_left = dp[(li + 1) * cols + rj];
                int skip_right = dp[li * cols + (rj + 1)];
                dp[index] = skip_left >= skip_right ? skip_left : skip_right;
            }
        }
    }

    DiffOpList ops;
    memset(&ops, 0, sizeof(ops));
    size_t i = 0;
    size_t j = 0;
    while (i < left->len || j < right->len) {
        if (i < left->len && j < right->len && strcmp(left->items[i], right->items[j]) == 0) {
            diff_op_list_push(&ops, (DiffOp){'=', i, j});
            i++;
            j++;
        } else if (j == right->len || (i < left->len && dp[(i + 1) * cols + j] >= dp[i * cols + (j + 1)])) {
            diff_op_list_push(&ops, (DiffOp){'-', i, SIZE_MAX});
            i++;
        } else {
            diff_op_list_push(&ops, (DiffOp){'+', SIZE_MAX, j});
            j++;
        }
    }

    size_t op_index = 0;
    while (op_index < ops.len) {
        if (ops.items[op_index].kind == '=') {
            add_pair_copy(view,
                          left->items[ops.items[op_index].left_index],
                          right->items[ops.items[op_index].right_index],
                          ops.items[op_index].left_index + 1,
                          ops.items[op_index].right_index + 1,
                          false,
                          false);
            op_index++;
            continue;
        }

        size_t del_start = op_index;
        size_t del_count = 0;
        while (op_index < ops.len && ops.items[op_index].kind == '-') {
            del_count++;
            op_index++;
        }
        size_t ins_start = op_index;
        size_t ins_count = 0;
        while (op_index < ops.len && ops.items[op_index].kind == '+') {
            ins_count++;
            op_index++;
        }

        size_t pair_count = del_count > ins_count ? del_count : ins_count;
        for (size_t k = 0; k < pair_count; k++) {
            const char *left_text = k < del_count ? left->items[ops.items[del_start + k].left_index] : NULL;
            const char *right_text = k < ins_count ? right->items[ops.items[ins_start + k].right_index] : NULL;
            size_t left_line_no = k < del_count ? ops.items[del_start + k].left_index + 1 : 0;
            size_t right_line_no = k < ins_count ? ops.items[ins_start + k].right_index + 1 : 0;
            add_pair_copy(view, left_text, right_text, left_line_no, right_line_no, left_text != NULL, right_text != NULL);
        }
    }

    free(dp);
    free(ops.items);
}

static void build_text_diff(SideBySideDiff *view, const StringList *left_lines, const StringList *right_lines) {
    size_t cell_count = (left_lines->len + 1) * (right_lines->len + 1);
    if (cell_count > MAX_LCS_CELLS) {
        build_naive_pairs(view, left_lines, right_lines);
    } else {
        build_lcs_pairs(view, left_lines, right_lines);
    }
}

static void load_diff_view(AppState *app) {
    size_t entry_index = selected_entry_index(app);
    if (entry_index == SIZE_MAX) {
        return;
    }

    const DiffEntry *entry = &app->entries.items[entry_index];
    if (!entry_has_text_diff(entry)) {
        snprintf(app->status, sizeof(app->status), "Selected entry does not support a text diff");
        return;
    }

    reset_diff_view(app);

    char *left_path = path_join(app->left_root, entry->relative_path);
    char *right_path = path_join(app->right_root, entry->relative_path);
    FileBuffer left_buffer = read_file_buffer(left_path);
    FileBuffer right_buffer = read_file_buffer(right_path);

    if (left_buffer.data == NULL || right_buffer.data == NULL) {
        snprintf(app->status, sizeof(app->status), "Failed to read %s", entry->relative_path);
        free(left_path);
        free(right_path);
        free(left_buffer.data);
        free(right_buffer.data);
        return;
    }

    if (left_buffer.binary || right_buffer.binary) {
        add_pair_copy(&app->diff_view,
                      left_buffer.binary ? "[binary file]" : NULL,
                      right_buffer.binary ? "[binary file]" : NULL,
                      0,
                      0,
                      true,
                      true);
        snprintf(app->status, sizeof(app->status), "Opened binary placeholder diff for %s", entry->relative_path);
    } else {
        StringList left_lines = split_lines(left_buffer.data);
        StringList right_lines = split_lines(right_buffer.data);
        build_text_diff(&app->diff_view, &left_lines, &right_lines);
        string_list_free(&left_lines);
        string_list_free(&right_lines);

        if (left_buffer.truncated || right_buffer.truncated) {
            snprintf(app->status, sizeof(app->status), "Opened truncated diff for %s (preview limited to %d bytes per side)",
                     entry->relative_path,
                     MAX_FILE_PREVIEW_BYTES);
        } else {
            snprintf(app->status, sizeof(app->status), "Opened side-by-side diff for %s", entry->relative_path);
        }
    }

    app->diff_view.entry_index = entry_index;
    app->diff_view.scroll = 0;
    app->diff_view.loaded = true;
    app->mode = MODE_DIFF;

    free(left_path);
    free(right_path);
    free(left_buffer.data);
    free(right_buffer.data);
}

static void ensure_browser_visible(AppState *app, int rows) {
    if (app->selected_visible < app->scroll) {
        app->scroll = app->selected_visible;
    } else if (app->selected_visible >= app->scroll + (size_t)rows) {
        app->scroll = app->selected_visible - (size_t)rows + 1;
    }
}

static void ensure_diff_visible(AppState *app, int rows) {
    if (app->diff_view.scroll + (size_t)rows > app->diff_view.len && app->diff_view.len > (size_t)rows) {
        app->diff_view.scroll = app->diff_view.len - (size_t)rows;
    }
}

static void init_colors(void) {
    start_color();
    use_default_colors();
    init_pair(1, COLOR_WHITE, -1);
    init_pair(2, COLOR_RED, -1);
    init_pair(3, COLOR_CYAN, -1);
    init_pair(4, COLOR_YELLOW, -1);
    init_pair(5, COLOR_MAGENTA, -1);
}

static void draw_diff_pane_line(int row, int col, int width, const char *line_no, const char *text, int color) {
    if (width <= 0) {
        return;
    }
    move(row, col);
    for (int i = 0; i < width; i++) {
        addch(' ');
    }
    attron(COLOR_PAIR(color));
    draw_text_clipped(row, col, width, "%4s %s", line_no, text == NULL ? "" : text);
    attroff(COLOR_PAIR(color));
}

static void draw_diff_mode(AppState *app, int rows, int cols) {
    if (!app->diff_view.loaded || app->diff_view.entry_index >= app->entries.len) {
        draw_text_clipped(2, 0, cols, "No diff is loaded.");
        draw_text_clipped(rows - 1, 0, cols, "Press q to return");
        return;
    }

    const DiffEntry *entry = &app->entries.items[app->diff_view.entry_index];
    int separator = cols / 2;
    int left_width = separator;
    int right_col = separator + 1;
    int right_width = cols - right_col;
    int body_top = 5;
    int body_rows = rows - body_top - 3;
    if (body_rows < 1) {
        body_rows = 1;
    }

    char left_mode[16] = "-";
    char right_mode[16] = "-";
    char left_time[64] = "-";
    char right_time[64] = "-";
    char left_size[32] = "-";
    char right_size[32] = "-";
    char left_counts[64] = "";
    char right_counts[64] = "";
    if (entry->left.exists) {
        format_mode(entry->left.mode, left_mode, sizeof(left_mode));
        format_time_value(entry->left.mtime_sec, entry->left.mtime_nsec, left_time, sizeof(left_time));
    }
    if (entry->right.exists) {
        format_mode(entry->right.mode, right_mode, sizeof(right_mode));
        format_time_value(entry->right.mtime_sec, entry->right.mtime_nsec, right_time, sizeof(right_time));
    }
    format_entry_size(app, entry, app->diff_view.entry_index, true, left_size, sizeof(left_size));
    format_entry_size(app, entry, app->diff_view.entry_index, false, right_size, sizeof(right_size));
    format_entry_counts(app, entry, app->diff_view.entry_index, true, left_counts, sizeof(left_counts));
    format_entry_counts(app, entry, app->diff_view.entry_index, false, right_counts, sizeof(right_counts));
    int time_cmp = compare_mtime(&entry->left, &entry->right);

    draw_text_clipped(2, 0, cols, "Diff: %s", entry->relative_path);
    draw_text_clipped(3, 0, left_width, "Left file");
    draw_text_clipped(3, right_col, right_width, "Right file");
    mvaddch(2, separator, ACS_VLINE);
    mvaddch(3, separator, ACS_VLINE);
    mvhline(4, 0, ACS_HLINE, cols);
    for (int row = body_top; row < rows - 3; row++) {
        mvaddch(row, separator, ACS_VLINE);
    }

    for (int i = 0; i < body_rows; i++) {
        size_t index = app->diff_view.scroll + (size_t)i;
        int row = body_top + i;
        if (index >= app->diff_view.len) {
            move(row, 0);
            clrtoeol();
            mvaddch(row, separator, ACS_VLINE);
            continue;
        }

        const DiffLinePair *pair = &app->diff_view.items[index];
        char left_no[8] = "";
        char right_no[8] = "";
        if (pair->left_line_no > 0) {
            snprintf(left_no, sizeof(left_no), "%zu", pair->left_line_no);
        }
        if (pair->right_line_no > 0) {
            snprintf(right_no, sizeof(right_no), "%zu", pair->right_line_no);
        }

        bool insertion_only = pair->left_text == NULL && pair->right_text != NULL;
        bool deletion_only = pair->left_text != NULL && pair->right_text == NULL;
        int left_color = pair->left_changed ? (deletion_only ? 4 : 4) : 1;
        int right_color = pair->right_changed ? (insertion_only ? 3 : 4) : 1;
        if (pair->left_text == NULL) {
            left_color = 2;
        }
        if (pair->right_text == NULL) {
            right_color = 2;
        }
        const char *left_text = pair->left_text == NULL ? "-" : pair->left_text;
        const char *right_text = pair->right_text == NULL ? "-" : pair->right_text;
        draw_diff_pane_line(row, 0, left_width, left_no, left_text, left_color);
        draw_diff_pane_line(row, right_col, right_width, right_no, right_text, right_color);
        mvaddch(row, separator, ACS_VLINE);
    }

    draw_text_clipped(rows - 3, 0, cols, "Keys: Up/Down/PgUp/PgDn/j/k scroll  Left/h/q/Esc return to browser  Size:%s  Counts:%s",
                      app->recursive_size_enabled ? "tree" : "entry",
                      app->child_counts_enabled ? "on" : "off");
    draw_text_clipped(rows - 2, 0, left_width, "Left:  %s  sz=%s  m=%s%s",
                      entry->left.exists ? type_label(entry->left.type) : "missing",
                      left_size,
                      left_mode,
                      left_counts);
    draw_text_clipped(rows - 2, right_col, right_width, "Right: %s  sz=%s  m=%s%s",
                      entry->right.exists ? type_label(entry->right.type) : "missing",
                      right_size,
                      right_mode,
                      right_counts);
    draw_mtime_status_line(rows - 1, 0, left_width, left_time, time_cmp > 0, time_cmp < 0);
    draw_mtime_status_line(rows - 1, right_col, right_width, right_time, time_cmp < 0, time_cmp > 0);
}

static void run_ui(AppState *app) {
    initscr();
    cbreak();
    noecho();
    keypad(stdscr, true);
    curs_set(0);
    init_colors();

    for (;;) {
        clear();
        int rows;
        int cols;
        getmaxyx(stdscr, rows, cols);
        draw_header(app, cols);

        if (app->mode == MODE_BROWSER) {
            int visible_rows = rows - 9;
            if (visible_rows < 1) {
                visible_rows = 1;
            }
            ensure_browser_visible(app, visible_rows);
            draw_browser(app, rows, cols);
        } else {
            int visible_rows = rows - 6;
            if (visible_rows < 1) {
                visible_rows = 1;
            }
            ensure_diff_visible(app, visible_rows);
            draw_diff_mode(app, rows, cols);
        }

        refresh();

        int ch = getch();
        if (app->mode == MODE_BROWSER) {
            int visible_rows = rows - 9;
            if (visible_rows < 1) {
                visible_rows = 1;
            }

            if (ch == 'q' || ch == 'Q') {
                break;
            }
            if (ch == 'r' || ch == 'R') {
                rescan(app);
                continue;
            }
            if (ch == 'e' || ch == 'E') {
                app->expansion_enabled = !app->expansion_enabled;
                snprintf(app->status, sizeof(app->status), "Folder expansion %s in %s",
                         app->expansion_enabled ? "enabled" : "disabled",
                         display_path(app->current_prefix));
                continue;
            }
            if (ch == 's' || ch == 'S') {
                app->recursive_size_enabled = !app->recursive_size_enabled;
                snprintf(app->status, sizeof(app->status), "Recursive size mode %s in %s",
                         app->recursive_size_enabled ? "enabled" : "disabled",
                         display_path(app->current_prefix));
                continue;
            }
            if (ch == 'c' || ch == 'C') {
                app->child_counts_enabled = !app->child_counts_enabled;
                snprintf(app->status, sizeof(app->status), "Descendant counts %s in %s",
                         app->child_counts_enabled ? "enabled" : "disabled",
                         display_path(app->current_prefix));
                continue;
            }
            if (ch == KEY_BACKSPACE || ch == 127 || ch == 'u' || ch == 'U') {
                enter_parent_directory(app);
                continue;
            }
            if ((ch == KEY_UP || ch == 'k' || ch == 'K') && app->selected_visible > 0) {
                app->selected_visible--;
                continue;
            }
            if ((ch == KEY_DOWN || ch == 'j' || ch == 'J') && app->selected_visible + 1 < app->visible_entries.len) {
                app->selected_visible++;
                continue;
            }
            if (ch == KEY_PPAGE) {
                size_t delta = (size_t)visible_rows;
                app->selected_visible = app->selected_visible > delta ? app->selected_visible - delta : 0;
                continue;
            }
            if (ch == KEY_NPAGE && app->visible_entries.len > 0) {
                size_t delta = (size_t)visible_rows;
                size_t max_index = app->visible_entries.len - 1;
                app->selected_visible = app->selected_visible + delta < max_index ? app->selected_visible + delta : max_index;
                continue;
            }
            if (ch == KEY_LEFT || ch == 'h' || ch == 'H') {
                enter_parent_directory(app);
                continue;
            }
            if (ch == ' ') {
                if (app->expansion_enabled) {
                    toggle_selected_directory(app, false, false);
                } else {
                    snprintf(app->status, sizeof(app->status), "Folder expansion is disabled; press e to enable it");
                }
                continue;
            }
            if (ch == KEY_RIGHT || ch == 'l' || ch == 'L') {
                size_t entry_index = selected_entry_index(app);
                if (entry_index != SIZE_MAX && entry_is_directory(&app->entries.items[entry_index])) {
                    enter_selected_directory(app);
                } else {
                    load_diff_view(app);
                }
                continue;
            }
            if (ch == '\n' || ch == '\r' || ch == KEY_ENTER) {
                size_t entry_index = selected_entry_index(app);
                if (entry_index != SIZE_MAX && entry_is_directory(&app->entries.items[entry_index])) {
                    enter_selected_directory(app);
                } else {
                    load_diff_view(app);
                }
                continue;
            }
        } else {
            int visible_rows = rows - 6;
            if (visible_rows < 1) {
                visible_rows = 1;
            }

            if (ch == 'q' || ch == 'Q' || ch == 27 || ch == KEY_LEFT || ch == 'h' || ch == 'H') {
                app->mode = MODE_BROWSER;
                snprintf(app->status, sizeof(app->status), "Returned to browser");
                continue;
            }
            if (ch == 's' || ch == 'S') {
                app->recursive_size_enabled = !app->recursive_size_enabled;
                snprintf(app->status, sizeof(app->status), "Recursive size mode %s",
                         app->recursive_size_enabled ? "enabled" : "disabled");
                continue;
            }
            if (ch == 'c' || ch == 'C') {
                app->child_counts_enabled = !app->child_counts_enabled;
                snprintf(app->status, sizeof(app->status), "Descendant counts %s",
                         app->child_counts_enabled ? "enabled" : "disabled");
                continue;
            }
            if ((ch == KEY_UP || ch == 'k' || ch == 'K') && app->diff_view.scroll > 0) {
                app->diff_view.scroll--;
                continue;
            }
            if ((ch == KEY_DOWN || ch == 'j' || ch == 'J') && app->diff_view.scroll + 1 < app->diff_view.len) {
                app->diff_view.scroll++;
                continue;
            }
            if (ch == KEY_PPAGE) {
                size_t delta = (size_t)visible_rows;
                app->diff_view.scroll = app->diff_view.scroll > delta ? app->diff_view.scroll - delta : 0;
                continue;
            }
            if (ch == KEY_NPAGE && app->diff_view.len > 0) {
                size_t delta = (size_t)visible_rows;
                size_t max_scroll = app->diff_view.len > (size_t)visible_rows ? app->diff_view.len - (size_t)visible_rows : 0;
                app->diff_view.scroll = app->diff_view.scroll + delta < max_scroll ? app->diff_view.scroll + delta : max_scroll;
                continue;
            }
        }
    }

    endwin();
}

static bool validate_directory(const char *path) {
    struct stat st;
    return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s LEFT_DIR RIGHT_DIR\n", argv[0]);
        return 1;
    }

    if (!validate_directory(argv[1]) || !validate_directory(argv[2])) {
        fprintf(stderr, "Both arguments must be existing directories.\n");
        return 1;
    }

    AppState app;
    memset(&app, 0, sizeof(app));
    app.base_left_root = realpath(argv[1], NULL);
    app.base_right_root = realpath(argv[2], NULL);
    if (app.base_left_root == NULL || app.base_right_root == NULL) {
        fprintf(stderr, "Failed to resolve absolute paths.\n");
        free(app.base_left_root);
        free(app.base_right_root);
        return 1;
    }
    update_context_roots(&app, "");

    rescan(&app);
    run_ui(&app);

    reset_diff_view(&app);
    free_entries(&app.entries);
    free_tree_stats(&app.left_stats);
    free_tree_stats(&app.right_stats);
    free(app.expanded);
    index_list_free(&app.visible_entries);
    free(app.current_prefix);
    free(app.base_left_root);
    free(app.base_right_root);
    free(app.left_root);
    free(app.right_root);
    return 0;
}
