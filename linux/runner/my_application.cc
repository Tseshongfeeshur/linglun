// #include "my_application.h"

// #include <flutter_linux/flutter_linux.h>
// #ifdef GDK_WINDOWING_X11
// #include <gdk/gdkx.h>
// #endif

// #include "flutter/generated_plugin_registrant.h"

// struct _MyApplication {
//   GtkApplication parent_instance;
//   char** dart_entrypoint_arguments;
// };

// G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// // Called when first Flutter frame received.
// static void first_frame_cb(MyApplication* self, FlView* view) {
//   gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
// }

// // Implements GApplication::activate.
// static void my_application_activate(GApplication* application) {
//   MyApplication* self = MY_APPLICATION(application);
//   GtkWindow* window =
//       GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

//   // Use a header bar when running in GNOME as this is the common style used
//   // by applications and is the setup most users will be using (e.g. Ubuntu
//   // desktop).
//   // If running on X and not using GNOME then just use a traditional title bar
//   // in case the window manager does more exotic layout, e.g. tiling.
//   // If running on Wayland assume the header bar will work (may need changing
//   // if future cases occur).
//   gboolean use_header_bar = TRUE;
// #ifdef GDK_WINDOWING_X11
//   GdkScreen* screen = gtk_window_get_screen(window);
//   if (GDK_IS_X11_SCREEN(screen)) {
//     const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
//     if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
//       use_header_bar = FALSE;
//     }
//   }
// #endif
//   if (use_header_bar) {
//     GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
//     gtk_widget_show(GTK_WIDGET(header_bar));
//     gtk_header_bar_set_title(header_bar, "linglun");
//     gtk_header_bar_set_show_close_button(header_bar, TRUE);
//     gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
//   } else {
//     gtk_window_set_title(window, "linglun");
//   }

//   gtk_window_set_default_size(window, 1280, 720);

//   g_autoptr(FlDartProject) project = fl_dart_project_new();
//   fl_dart_project_set_dart_entrypoint_arguments(
//       project, self->dart_entrypoint_arguments);

//   FlView* view = fl_view_new(project);
//   GdkRGBA background_color;
//   // Background defaults to black, override it here if necessary, e.g. #00000000
//   // for transparent.
//   gdk_rgba_parse(&background_color, "#000000");
//   fl_view_set_background_color(view, &background_color);
//   gtk_widget_show(GTK_WIDGET(view));
//   gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

//   // Show the window when Flutter renders.
//   // Requires the view to be realized so we can start rendering.
//   g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
//                            self);
//   gtk_widget_realize(GTK_WIDGET(view));

//   fl_register_plugins(FL_PLUGIN_REGISTRY(view));

//   gtk_widget_grab_focus(GTK_WIDGET(view));
// }

// // Implements GApplication::local_command_line.
// static gboolean my_application_local_command_line(GApplication* application,
//                                                   gchar*** arguments,
//                                                   int* exit_status) {
//   MyApplication* self = MY_APPLICATION(application);
//   // Strip out the first argument as it is the binary name.
//   self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

//   g_autoptr(GError) error = nullptr;
//   if (!g_application_register(application, nullptr, &error)) {
//     g_warning("Failed to register: %s", error->message);
//     *exit_status = 1;
//     return TRUE;
//   }

//   g_application_activate(application);
//   *exit_status = 0;

//   return TRUE;
// }

// // Implements GApplication::startup.
// static void my_application_startup(GApplication* application) {
//   // MyApplication* self = MY_APPLICATION(object);

//   // Perform any actions required at application startup.

//   G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
// }

// // Implements GApplication::shutdown.
// static void my_application_shutdown(GApplication* application) {
//   // MyApplication* self = MY_APPLICATION(object);

//   // Perform any actions required at application shutdown.

//   G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
// }

// // Implements GObject::dispose.
// static void my_application_dispose(GObject* object) {
//   MyApplication* self = MY_APPLICATION(object);
//   g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
//   G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
// }

// static void my_application_class_init(MyApplicationClass* klass) {
//   G_APPLICATION_CLASS(klass)->activate = my_application_activate;
//   G_APPLICATION_CLASS(klass)->local_command_line =
//       my_application_local_command_line;
//   G_APPLICATION_CLASS(klass)->startup = my_application_startup;
//   G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
//   G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
// }

// static void my_application_init(MyApplication* self) {}

// MyApplication* my_application_new() {
//   // Set the program name to the application ID, which helps various systems
//   // like GTK and desktop environments map this running application to its
//   // corresponding .desktop file. This ensures better integration by allowing
//   // the application to be recognized beyond its binary name.
//   g_set_prgname(APPLICATION_ID);

//   return MY_APPLICATION(g_object_new(my_application_get_type(),
//                                      "application-id", APPLICATION_ID, "flags",
//                                      G_APPLICATION_NON_UNIQUE, nullptr));
// }

#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#include <glib/gstdio.h>

#include "flutter/generated_plugin_registrant.h"

// ---- Tunables -------------------------------------------------------------
#define APP_TITLE "linglun"
#define DEFAULT_WIDTH 1280
#define DEFAULT_HEIGHT 720
#define MIN_WIDTH 300
#define MIN_HEIGHT 480
// ---------------------------------------------------------------------------

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;

  // Window state tracking (for persistence across launches).
  gint width;
  gint height;
  gboolean maximized;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// ---- Window state persistence ---------------------------------------------

static gchar* state_file_path() {
  return g_build_filename(g_get_user_config_dir(), APPLICATION_ID,
                          "window.ini", nullptr);
}

static void load_window_state(MyApplication* self) {
  self->width = DEFAULT_WIDTH;
  self->height = DEFAULT_HEIGHT;
  self->maximized = FALSE;

  g_autofree gchar* path = state_file_path();
  g_autoptr(GKeyFile) keyfile = g_key_file_new();
  if (!g_key_file_load_from_file(keyfile, path, G_KEY_FILE_NONE, nullptr)) {
    return;
  }

  gint w = g_key_file_get_integer(keyfile, "window", "width", nullptr);
  gint h = g_key_file_get_integer(keyfile, "window", "height", nullptr);
  // Reject garbage / absurd values (e.g. a monitor that no longer exists).
  if (w >= MIN_WIDTH && h >= MIN_HEIGHT && w <= 16384 && h <= 16384) {
    self->width = w;
    self->height = h;
  }
  self->maximized =
      g_key_file_get_boolean(keyfile, "window", "maximized", nullptr);
}

static void save_window_state(MyApplication* self) {
  g_autofree gchar* path = state_file_path();
  g_autofree gchar* dir = g_path_get_dirname(path);
  g_mkdir_with_parents(dir, 0700);

  g_autoptr(GKeyFile) keyfile = g_key_file_new();
  g_key_file_set_integer(keyfile, "window", "width", self->width);
  g_key_file_set_integer(keyfile, "window", "height", self->height);
  g_key_file_set_boolean(keyfile, "window", "maximized", self->maximized);
  g_key_file_save_to_file(keyfile, path, nullptr);
}

// Keep track of the last "normal" (not maximized / fullscreen / tiled) size.
static gboolean configure_event_cb(GtkWidget* widget, GdkEventConfigure* event,
                                   gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  GdkWindow* gdk_window = gtk_widget_get_window(widget);
  if (gdk_window != nullptr) {
    GdkWindowState state = gdk_window_get_state(gdk_window);
    if (!(state & (GDK_WINDOW_STATE_MAXIMIZED | GDK_WINDOW_STATE_FULLSCREEN |
                   GDK_WINDOW_STATE_TILED))) {
      self->width = event->width;
      self->height = event->height;
    }
  }
  return FALSE;  // let other handlers (Flutter) see the event
}

static gboolean window_state_event_cb(GtkWidget* widget,
                                      GdkEventWindowState* event,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (event->changed_mask & GDK_WINDOW_STATE_MAXIMIZED) {
    self->maximized =
        (event->new_window_state & GDK_WINDOW_STATE_MAXIMIZED) != 0;
  }
  return FALSE;
}

static gboolean delete_event_cb(GtkWidget* widget, GdkEvent* event,
                                gpointer user_data) {
  save_window_state(MY_APPLICATION(user_data));
  return FALSE;  // proceed with the normal close
}

// ---- Window decoration policy ---------------------------------------------

// Client-side header bar only where it is the native look (GNOME). On KDE,
// XFCE, Cinnamon, tiling WMs, etc. (X11 *or* Wayland) use the compositor's
// regular title bar so the window matches the rest of the desktop.
static gboolean should_use_header_bar(GtkWindow* window) {
  // Honour the standard GTK escape hatch.
  const gchar* csd = g_getenv("GTK_CSD");
  if (g_strcmp0(csd, "0") == 0) return FALSE;
  if (g_strcmp0(csd, "1") == 0) return TRUE;

  const gchar* desktop = g_getenv("XDG_CURRENT_DESKTOP");
  if (desktop != nullptr && *desktop != '\0') {
    g_autofree gchar* upper = g_ascii_strup(desktop, -1);
    return g_strrstr(upper, "GNOME") != nullptr;
  }

#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    return g_strcmp0(wm_name, "GNOME Shell") == 0;
  }
#endif
  return TRUE;  // Unknown Wayland compositor: assume header bar works.
}

// ---- Application ----------------------------------------------------------

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  gtk_widget_show(toplevel);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  // Single-instance behaviour: if a window already exists, just raise it.
  GtkWindow* existing =
      gtk_application_get_active_window(GTK_APPLICATION(application));
  if (existing != nullptr) {
    gtk_window_present(existing);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  if (should_use_header_bar(window)) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, APP_TITLE);
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, APP_TITLE);
  }

  // Icon looked up from the icon theme by application ID (matches the
  // installed .desktop file's Icon= entry).
  gtk_window_set_icon_name(window, APPLICATION_ID);

  // Minimum size, so the Flutter layout can't be crushed.
  GdkGeometry geometry;
  geometry.min_width = MIN_WIDTH;
  geometry.min_height = MIN_HEIGHT;
  gtk_window_set_geometry_hints(window, nullptr, &geometry, GDK_HINT_MIN_SIZE);

  // Restore last size / maximized state.
  load_window_state(self);
  gtk_window_set_default_size(window, self->width, self->height);
  if (self->maximized) {
    gtk_window_maximize(window);
  }

  g_signal_connect(window, "configure-event", G_CALLBACK(configure_event_cb),
                   self);
  g_signal_connect(window, "window-state-event",
                   G_CALLBACK(window_state_event_cb), self);
  g_signal_connect(window, "delete-event", G_CALLBACK(delete_event_cb), self);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);

  // Use the GTK theme's background instead of hard-coded black, so resizing
  // or the pre-first-frame period doesn't flash black in light themes.
  GdkRGBA background_color;
  GtkStyleContext* style = gtk_widget_get_style_context(GTK_WIDGET(window));
  if (!gtk_style_context_lookup_color(style, "theme_bg_color",
                                      &background_color)) {
    gdk_rgba_parse(&background_color, "#000000");
  }
  fl_view_set_background_color(view, &background_color);

  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->width = DEFAULT_WIDTH;
  self->height = DEFAULT_HEIGHT;
  self->maximized = FALSE;
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file (Wayland app_id / X11 WM_CLASS).
  g_set_prgname(APPLICATION_ID);
  g_set_application_name(APP_TITLE);

  // Unique application: a second launch activates the running instance
  // instead of opening a duplicate window.
#if GLIB_CHECK_VERSION(2, 74, 0)
  GApplicationFlags flags = G_APPLICATION_DEFAULT_FLAGS;
#else
  GApplicationFlags flags = G_APPLICATION_FLAGS_NONE;
#endif

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     flags, nullptr));
}