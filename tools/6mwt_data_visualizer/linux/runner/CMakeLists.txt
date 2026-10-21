cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES C CXX)

# Embed the icon so direct launches do not depend on a system icon install.
find_program(GLIB_COMPILE_RESOURCES glib-compile-resources REQUIRED)
set(BRANDING_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources")
set(BRANDING_SOURCE "${CMAKE_CURRENT_BINARY_DIR}/branding.c")
add_custom_command(
  OUTPUT "${BRANDING_SOURCE}"
  COMMAND "${GLIB_COMPILE_RESOURCES}"
    "${BRANDING_DIR}/branding.gresource.xml"
    --sourcedir=${BRANDING_DIR} --generate-source --target=${BRANDING_SOURCE}
  DEPENDS "${BRANDING_DIR}/branding.gresource.xml" "${BRANDING_DIR}/app_icon.png"
  VERBATIM
)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${BRANDING_SOURCE}"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
