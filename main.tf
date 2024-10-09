# Upload Traceable schema.lua to Kong Konnect
resource "konnect_gateway_custom_plugin_schema" "traceble_plugin" {
  control_plane_id = "${var.konnect_control_plane_id}"
  lua_schema       = "return {\n  name = \"traceable\",\n  fields = {\n    {\n      config = {\n        type = \"record\",\n        fields = {\n          { ext_cap_endpoint = { type = \"string\", required = true } },\n          { allow_on_failure = { type = \"boolean\", required = true, default = true } },\n          { service_name = {type = \"string\", required = false, default = \"kong\"} },\n          { timeout = { type = \"number\", required = false, default = 500 } },\n        },\n      },\n    },\n  },\n}\n"
}