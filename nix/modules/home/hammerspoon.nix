{ config, lib, ... }:

{
  # Deploy Hammerspoon configuration
  home.file.".hammerspoon/init.lua".text = ''
    -- Hammerspoon Config: Auto-adjust IDE font sizes based on external display
    -- Monitors display connection/disconnection events

    local log = hs.logger.new('display-font-adjuster', 'info')

    -- Configuration
    local config = {
      -- Font sizes
      fontSizeWithMonitor = 15,
      fontSizeWithoutMonitor = 12,

      -- JetBrains IDE patterns (ProductName + Version)
      idePatterns = {
        "GoLand*",
        "WebStorm*",
        "RustRover*",
        "IntelliJIdea*",
        "PyCharm*",
        "CLion*",
        "DataGrip*"
      }
    }

    -- Get all connected screens
    local function getScreenCount()
      return #hs.screen.allScreens()
    end

    -- Update font size in JetBrains IDE editor.xml files
    local function updateJetBrainsIDEFontSize(fontSize)
      local jetbrainsPath = os.getenv("HOME") .. "/Library/Application Support/JetBrains"

      log.i(string.format("Updating JetBrains IDE font sizes to %d", fontSize))

      -- Find all JetBrains IDE directories
      for _, pattern in ipairs(config.idePatterns) do
        local findCmd = string.format(
          'find "%s" -maxdepth 1 -type d -name "%s" 2>/dev/null',
          jetbrainsPath,
          pattern
        )

        local handle = io.popen(findCmd)
        if handle then
          for ideDir in handle:lines() do
            local editorXmlPath = ideDir .. "/options/editor.xml"

            -- Check if editor.xml exists
            local file = io.open(editorXmlPath, "r")
            if file then
              file:close()

              -- Read the file
              local content
              file = io.open(editorXmlPath, "r")
              if file then
                content = file:read("*all")
                file:close()

                -- Update FONT_SIZE values
                local modified = false
                local newContent = content

                -- Update FONT_SIZE
                newContent, count = string.gsub(
                  newContent,
                  '(<option name="FONT_SIZE" value=")%%d+(")',
                  '%%1' .. fontSize .. '%%2'
                )
                if count > 0 then modified = true end

                -- Update FONT_SIZE_2D
                newContent, count = string.gsub(
                  newContent,
                  '(<option name="FONT_SIZE_2D" value=")%%d+%%.?%%d*(")',
                  '%%1' .. fontSize .. '.0%%2'
                )
                if count > 0 then modified = true end

                -- Write back if modified
                if modified then
                  file = io.open(editorXmlPath, "w")
                  if file then
                    file:write(newContent)
                    file:close()
                    log.i(string.format("Updated: %s", editorXmlPath))
                  else
                    log.e(string.format("Failed to write: %s", editorXmlPath))
                  end
                end
              end
            end
          end
          handle:close()
        end
      end

      -- Show notification
      hs.notify.new({
        title = "IDE Font Size Updated",
        informativeText = string.format("Font size changed to %d", fontSize)
      }):send()
    end

    -- Handle screen configuration changes
    local function screenChanged()
      local screenCount = getScreenCount()
      log.i(string.format("Screen configuration changed. Total screens: %d", screenCount))

      if screenCount > 1 then
        -- External monitor connected
        log.i("External monitor detected - setting font size to " .. config.fontSizeWithMonitor)
        updateJetBrainsIDEFontSize(config.fontSizeWithMonitor)
      else
        -- Only built-in display
        log.i("Single display detected - setting font size to " .. config.fontSizeWithoutMonitor)
        updateJetBrainsIDEFontSize(config.fontSizeWithoutMonitor)
      end
    end

    -- Set up screen watcher
    local screenWatcher = hs.screen.watcher.new(screenChanged)
    screenWatcher:start()

    log.i("Display font adjuster loaded. Monitoring " .. getScreenCount() .. " screen(s)")

    -- Show initial notification
    hs.notify.new({
      title = "Hammerspoon Loaded",
      informativeText = "Display font adjuster is active"
    }):send()

    -- Optional: Set initial font size based on current configuration
    -- Uncomment the next line if you want to adjust fonts on Hammerspoon load
    -- screenChanged()
  '';
}
