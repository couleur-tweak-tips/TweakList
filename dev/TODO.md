# To-do list for the CTT optimizer.

- Basic Requirements
  - Everything should be togglable depending on the users needs.
  - Should have verbose mode incase of issues
  - Should have Performance Changes (See Below)
  - Should have QOL Changes (See Below)

# Performance Based Changes
 - Change Win32PrioritySeparation
   - Changes the separation between background and foreground apps
 - Call Opt-Of to optimize optifine settings
   - you made it and understand it more than me
 - Call Opt-LC to optimize Lunar Client
   - you made it and understand it more than me
 - Disable extra services such as:
   - LanmanWorkstation (used in business areas)
   - LanmanServer (used to detect a NAS or file server, should 100% be optional)
   - RasMan (Remote access, hella security risk)
   - FontCache3.0.0.0 (Literally only helps office apps)
   - WpnService (Disables taskbar notifications, can be annoying and useless if you use a browser or use discord)
 - Optimize BCDEdit
   - Change TSyncPolicy to Enhanced
   - Changes the internal hardware clocks to more efficient
 - Disable Platform Tick
   - Don't disable for everyone as some BIOSes don't have platform ticks
 - Use High Performance Power Plan
   - This allows for good performance on all devices
   - doesn't need to disable power throttling
 - Disable Preemption
   - Disable the switching of priority for tasks for consistant performance and better gameplay

# Quality of Life Changes
 - Disable Telemetry
   - Do I need to explain this? Tracking, yuck.
 - Disable P2P windows updates
   - Disable Delivery Optimization for better networking performance
 - Disable Windows Defender
   - You should 100% keep the migitations enabled
 - Disable GameMode
   - Some people say that it helps many games but can actually cause issues with OBS and other apps
 - Turn everything off in the Privacy Section of Settings
   - Does way more good than harm, and prevents some PUPs from accessing the File system and File chooser.
