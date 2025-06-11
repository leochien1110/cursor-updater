# Cursor Updater

![Linux x86_64](https://img.shields.io/badge/Linux-x86__64-green?logo=linux&logoColor=white)
![Linux ARM64](https://img.shields.io/badge/Linux-ARM64-green?logo=linux&logoColor=white)


> In the era of AI, Cursor is one of the best AI agents for coding. However, it's UX for updating the IDE itself is such a pain in the ass. Therefore, I decide to build a simple service that will update the Cursor IDE itself daily. However, this might need a frequent maintenance due to the potential endpoint changes.


## How to run

1. Clone the repository
2. Run `./init.sh` to install the latest version of Cursor IDE. This will setup the cursor to your Application drawer.
3. Run `./cursor-updater.sh` to setup the daily updater service. This will install the systemd service and run the updater automatically daily.

That's it! The updater will now run daily at a random time (with up to 1 hour delay for system load balancing).

## Manual operations

- **Test the updater**: `sudo systemctl start cursor-update.service`
- **Check update logs**: `journalctl -u cursor-update.service -f`
- **Check timer status**: `systemctl status cursor-update.timer`
- **Stop daily updates**: `sudo systemctl stop cursor-update.timer`
- **Disable daily updates**: `sudo systemctl disable cursor-update.timer`

## How it works
The service is running via systemd service and timer.

0. The service will check the system architecture and download the corresponding version of Cursor IDE: linux-x64 and linux-arm64.
1. The service will check the latest version of Cursor IDE from the Cursor website daily.
2. The service will check if the current version of Cursor IDE under `/opt/cursor*` is the latest version. If it is, the service will exit.
3. The service will download the latest version of Cursor IDE.
4. The service will make the downloaded AppImage executable.
5. The service will move the AppImage to `/opt` and symlink to `cursor.appimage` so that the .desktop file can find it.
6. The service will restart the Cursor IDE if there's any running instance.

- `init.sh` will install the latest version of Cursor IDE and setup the cursor to your Application drawer.
- `cursor-updater.sh` will setup the daily updater service.
- `update-cursor.sh` will update the Cursor IDE to the latest version. This will run as the background job, so you don't need to worry about it.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Buy me a coffee

If you like this project, please ⭐ star the repository and ☕ buy me a coffee.


<a href="https://coff.ee/leochien1110" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
