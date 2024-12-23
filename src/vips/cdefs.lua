-- all the C declarations for lua-vips

local ffi = require "ffi"

-- GType is an int the size of a pointer ... I don't think we can just use
-- size_t, sadly
if ffi.arch == "x64" or ffi.arch == "arm64" then
    ffi.cdef [[
        typedef uint64_t GType;
    ]]
else
    ffi.cdef [[
        typedef uint32_t GType;
    ]]
end

ffi.cdef [[
    typedef struct _GValue {
        GType gtype;
        uint64_t data[2];
    } GValue;

    void *g_malloc (size_t size);
    void g_free (void *data);

    void g_object_ref (void *object);
    void g_object_unref (void *object);

    void g_value_init (GValue *value, GType gtype);
    void g_value_unset (GValue *value);
    const char *g_type_name (GType gtype);
    GType g_type_from_name (const char *name);
    GType g_type_fundamental (GType gtype);

    GType vips_blend_mode_get_type (void);
    GType vips_band_format_get_type (void);

    int vips_enum_from_nick (const char *domain,
        GType gtype, const char *str);
    const char *vips_enum_nick (GType gtype, int value);

    void g_value_set_boolean (GValue *value, int v_boolean);
    void g_value_set_int (GValue *value, int i);
    void g_value_set_double (GValue *value, double d);
    void g_value_set_enum (GValue *value, int e);
    void g_value_set_flags (GValue *value, unsigned int f);
    void g_value_set_string (GValue *value, const char *str);
    void vips_value_set_ref_string (GValue *value, const char *str);
    void g_value_set_object (GValue *value, void *object);
    void vips_value_set_array_double (GValue *value,
        const double *array, int n);
    void vips_value_set_array_int (GValue *value,
        const int *array, int n);
    void vips_value_set_array_image (GValue *value, int n);
    void vips_value_set_blob (GValue *value,
        void (*free_fn)(void *data), void *data, size_t length);
    void vips_value_set_blob_free (GValue *value,
        void *data, size_t length);

    int g_value_get_boolean (const GValue *value);
    int g_value_get_int (const GValue *value);
    double g_value_get_double (const GValue *value);
    int g_value_get_enum (const GValue *value);
    unsigned int g_value_get_flags (const GValue *value);
    const char *g_value_get_string (const GValue *value);
    const char *vips_value_get_ref_string (const GValue *value, size_t *length);
    void *g_value_get_object (const GValue *value);
    double *vips_value_get_array_double (const GValue *value, int *n);
    int *vips_value_get_array_int (const GValue *value, int *n);
    void *vips_value_get_blob (const GValue *value, size_t *length);

    typedef struct _GObject {
        void *g_type_instance;
        unsigned int ref_count;
        void *qdata;
    } GObject;

    typedef struct _VipsObject {
        GObject parent_instance;
        bool constructed;
        bool static_object;
        void *argument_table;
        char *nickname;
        char *description;
        bool preclose;
        bool close;
        bool postclose;
        size_t local_memory;
    } VipsObject;

    typedef struct _VipsObjectClass {
        // opaque
    } VipsObjectClass;

    typedef enum {
        G_PARAM_READABLE = 1,
        G_PARAM_WRITABLE = 2,
        G_PARAM_CONSTRUCT = 4,
        G_PARAM_CONSTRUCT_ONLY = 8,
        G_PARAM_LAX_VALIDATION = 16,
        G_PARAM_STATIC_NAME = 32,
        G_PARAM_PRIVATE = G_PARAM_STATIC_NAME,
        G_PARAM_STATIC_NICK = 64,
        G_PARAM_STATIC_BLURB = 128
    } GParamFlags;

    typedef struct _GParamSpec {
        void *g_type_instance;

        const char *name;
        GParamFlags flags;
        GType value_type;
        GType owner_type;

        // rest opaque
    } GParamSpec;

    typedef struct _VipsArgument {
        GParamSpec *pspec;
    } VipsArgument;

    typedef struct _VipsArgumentInstance {
        VipsArgument parent;

        // opaque
    } VipsArgumentInstance;

    typedef enum _VipsArgumentFlags {
        VIPS_ARGUMENT_NONE = 0,
        VIPS_ARGUMENT_REQUIRED = 1,
        VIPS_ARGUMENT_CONSTRUCT = 2,
        VIPS_ARGUMENT_SET_ONCE = 4,
        VIPS_ARGUMENT_SET_ALWAYS = 8,
        VIPS_ARGUMENT_INPUT = 16,
        VIPS_ARGUMENT_OUTPUT = 32,
        VIPS_ARGUMENT_DEPRECATED = 64,
        VIPS_ARGUMENT_MODIFY = 128
    } VipsArgumentFlags;

    typedef struct _VipsArgumentClass {
        VipsArgument parent;

        VipsObjectClass *object_class;
        VipsArgumentFlags flags;
        int priority;
        uint64_t offset;
    } VipsArgumentClass;

    int vips_object_get_argument (VipsObject *object,
        const char *name, GParamSpec **pspec,
        VipsArgumentClass **argument_class,
        VipsArgumentInstance **argument_instance);

    void g_object_set_property (VipsObject *object,
        const char *name, const GValue *value);
    void g_object_get_property (VipsObject *object,
        const char *name, GValue *value);

    void vips_object_print_all (void);

    int vips_object_set_from_string (VipsObject *object, const char *options);

    typedef struct _VipsImage {
        VipsObject parent_instance;

        // opaque
    } VipsImage;

    typedef struct _VipsConnection {
        VipsObject parent_instance;

        // opaque
    } VipsConnection;

    const char *vips_connection_filename (VipsConnection *connection);
    const char *vips_connection_nick (VipsConnection *connection);

    typedef struct _VipsSource {
        VipsConnection parent_instance;

        // opaque
    } VipsSource;

    typedef struct _VipsTarget {
        VipsConnection parent_instance;

        // opaque
    } VipsTarget;

    VipsSource *vips_source_new_from_descriptor (int descriptor);
    VipsSource *vips_source_new_from_file (const char *filename);
    // VipsSource *vips_source_new_from_blob (VipsBlob *blob);
    // VipsSource *vips_source_new_from_target (VipsTarget *target);
    VipsSource *vips_source_new_from_memory (const void *data, size_t size);
    // VipsSource *vips_source_new_from_options (const char *options);
    // void vips_source_minimise (VipsSource *source);
    // int vips_source_decode (VipsSource *source);
    // gint64 vips_source_read (VipsSource *source, void *data, size_t length);
    // gboolean vips_source_is_mappable (VipsSource *source);
    // gboolean vips_source_is_file (VipsSource *source);
    // const void *vips_source_map (VipsSource *source, size_t *length);
    // VipsBlob *vips_source_map_blob (VipsSource *source);
    // gint64 vips_source_seek (VipsSource *source, gint64 offset, int whence);
    // int vips_source_rewind (VipsSource *source);
    // gint64 vips_source_sniff_at_most (VipsSource *source, unsigned char **data, size_t length);
    // unsigned char *vips_source_sniff (VipsSource *source, size_t length);
    // gint64 vips_source_length (VipsSource *source);
    // VipsSourceCustom *vips_source_custom_new (void);
    // GInputStream *vips_g_input_stream_new_from_source (VipsSource *source);
    // VipsSourceGInputStream *vips_source_g_input_stream_new (GInputStream *stream);

    VipsTarget *vips_target_new_to_descriptor (int descriptor);
    VipsTarget *vips_target_new_to_file (const char *filename);
    VipsTarget *vips_target_new_to_memory (void);
    // VipsTarget *vips_target_new_temp (VipsTarget *target);
    // int vips_target_write (VipsTarget *target, const void *data, size_t length);
    // gint64 vips_target_read (VipsTarget *target, void *buffer, size_t length);
    // gint64 vips_target_seek (VipsTarget *target, gint64 offset, int whence);
    // int vips_target_end (VipsTarget *target);
    // unsigned char *vips_target_steal (VipsTarget *target, size_t *length);
    // char *vips_target_steal_text (VipsTarget *target);
    // int vips_target_putc (VipsTarget *target, int ch);
    // int vips_target_writes (VipsTarget *target, const char *str);
    // int vips_target_writef (VipsTarget *target, const char *fmt, ...);
    // int vips_target_write_amp (VipsTarget *target, const char *str);
    // VipsTargetCustom *vips_target_custom_new (void);

    const char *vips_foreign_find_load (const char *name);
    const char *vips_foreign_find_load_buffer (const void *data, size_t size);
    const char *vips_foreign_find_save (const char *name);
    const char *vips_foreign_find_save_buffer (const char *suffix);
    const char* vips_foreign_find_load_source (VipsSource *source);
    const char* vips_foreign_find_save_target (const char* suffix);

    VipsImage *vips_image_new_matrix_from_array (int width, int height,
        const double *array, int size);

    VipsImage *vips_image_new_from_memory (const void *data, size_t size,
        int width, int height, int bands, int format);
    unsigned char *vips_image_write_to_memory (VipsImage *image,
        size_t *size_out);

    VipsImage *vips_image_copy_memory (VipsImage *image);

    VipsImage **vips_value_get_array_image (const GValue *value, int *n);

    GType vips_image_get_typeof (const VipsImage *image, const char *name);
    int vips_image_get (const VipsImage *image, const char *name,
        GValue *value_copy);
    void vips_image_set (VipsImage *image, const char *name, GValue *value);
    int vips_image_remove (VipsImage *image, const char *name);

    int vips_image_hasalpha(VipsImage *image);

    char *vips_filename_get_filename (const char *vips_filename);
    char *vips_filename_get_options (const char *vips_filename);

    typedef struct _VipsOperation {
        VipsObject parent_instance;

        // opaque
    } VipsOperation;

    typedef struct _VipsInterpolate {
        VipsObject parent_instance;

        // opaque
    } VipsInterpolate;

    VipsInterpolate *vips_interpolate_new (const char *name);

    VipsOperation *vips_operation_new (const char *name);

    typedef void * (*VipsArgumentMapFn) (VipsOperation *object,
        GParamSpec *pspec,
        VipsArgumentClass *argument_class,
        VipsArgumentInstance *argument_instance,
        void *a, void *b);

    void *vips_argument_map (VipsOperation *object,
        VipsArgumentMapFn fn, void *a, void *b);

    void vips_object_get_args (VipsOperation *object,
        const char ***names, int **flags, int *n_args);

    VipsOperation *vips_cache_operation_build (VipsOperation *operation);
    void vips_object_unref_outputs (VipsOperation *operation);

    void vips_leak_set (int leak);
    void vips_cache_set_max (int max);
    void vips_cache_set_max (int max);
    int vips_cache_get_max (void);
    void vips_cache_set_max_mem (size_t max_mem);
    size_t vips_cache_get_max_mem (void);
    void vips_cache_set_max_files (int max_files);
    int vips_cache_get_max_files (void);

    void vips_concurrency_set (int concurrency);
    int vips_concurrency_get ();

    int vips_init (const char *argv0);
    int vips_version (int flag);

    const char *vips_error_buffer (void);
    void vips_error_clear (void);

]]
