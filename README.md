# PC Config
 
PC-Config is a collection of PowerShell scripts that will help you configure your Windows computer with items like the taskbar and folder options. You also get the ability to install MSI packages from files or URLs. PC-Config support the install of Chocolatey packages which is the prefered way of install software with this tool.

For now the main documentation is to look at the Config\State.json file which has all available options configured. You can then remove/add what you need to suit your setup.

#### Requirements
- Windows 10 (As this is the only one I have tested)
- PowerShell 7+ (Automatic installation is supported)
- Admin privileges (Automatic elevation not yet supported)
- Basic JSON knowledge
- Chocolatey if you specify any package with the chocolatey provider (Automatic installation of Chocolatey is supported)

#### How to use
- Edit the State.json file with what you need
- Execute Go.ps1 in a PowerShell shell

#### What's not working
- Default browser setting

#### To do
- Fix setting the default browser
- Support changing the default media player
- Ability to pass argument to MSI packages
- Install EXEs
- Daisy chain other PowerShell script(s)
- Create/import Task Scheduler jobs
- Any other feature you would like to have (Open an issue with an exemple of what you would like)

#### Other notes
You could in theory use the modules provided to build you own PowerShell script(s).
Thanks to Heath Stewart, the Windows Explorer restart function is provided here https://github.com/heaths/RestartManager

To help finding Chocolatey packages that you would like to install you can go to https://community.chocolatey.org/packages
