local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Adapter-neutral global projection. WezTerm consumes it; WezTerm does not own it.
local manifest_path = "/home/_404/src/contract.cuemod/workspace.projects.json"

local function read_file(path)
  local file, err = io.open(path, "r")
  if not file then
    wezterm.log_error("workspace project manifest unreadable: " .. path .. " :: " .. tostring(err))
    return nil
  end

  local body = file:read("*a")
  file:close()
  return body
end

local function load_manifest()
  local body = read_file(manifest_path)
  if not body or body == "" then
    return { projects = {} }
  end

  local ok, parsed = pcall(wezterm.json_parse, body)
  if not ok or type(parsed) ~= "table" then
    wezterm.log_error("workspace project manifest invalid json: " .. manifest_path)
    return { projects = {} }
  end

  if type(parsed.projects) ~= "table" then
    wezterm.log_error("workspace project manifest missing projects[]: " .. manifest_path)
    return { projects = {} }
  end

  return parsed
end

local function project_map(manifest)
  local by_id = {}
  for _, project in ipairs(manifest.projects or {}) do
    if type(project.id) == "string" then
      by_id[project.id] = project
    end
  end
  return by_id
end

local function choices_from_manifest(manifest)
  local choices = {}
  for _, project in ipairs(manifest.projects or {}) do
    if type(project.id) == "string" and type(project.label) == "string" then
      table.insert(choices, {
        label = project.label .. "  " .. project.root,
        id = project.id,
      })
    end
  end

  table.sort(choices, function(a, b)
    return a.label < b.label
  end)

  return choices
end

local function switch_to_project(window, pane, project)
  if not project then
    return
  end

  local wez = project.adapters and project.adapters.wezterm or {}
  local workspace = wez.workspace or project.id
  local cwd = wez.cwd or project.root or wezterm.home_dir
  local env = project.env or {}

  window:perform_action(
    act.SwitchToWorkspace({
      name = workspace,
      spawn = {
        cwd = cwd,
        set_environment_variables = env,
      },
    }),
    pane
  )
end

local function choose_project()
  local manifest = load_manifest()
  local by_id = project_map(manifest)
  local choices = choices_from_manifest(manifest)

  return act.InputSelector({
    title = "Project",
    fuzzy = true,
    choices = choices,
    action = wezterm.action_callback(function(window, pane, id, _label)
      if not id then
        return
      end

      switch_to_project(window, pane, by_id[id])
    end),
  })
end

function M.apply_to_config(config)
  config.keys = config.keys or {}

  table.insert(config.keys, {
    key = "s",
    mods = "ALT",
    action = choose_project(),
  })

  table.insert(config.keys, {
    key = "9",
    mods = "ALT",
    action = act.ShowLauncherArgs({
      flags = "FUZZY|WORKSPACES",
    }),
  })
end

return M
