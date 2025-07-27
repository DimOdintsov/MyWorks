#!/bin/bash
softwareupdate --install-rosetta --agree-to-license
show_notification() {
    local message="$1"
    # Определяем активного пользователя и его UID
    active_user=$(stat -f "%Su" /dev/console)
    user_id=$(id -u "$active_user")

    # Проверяем, что нашли пользователя и он не root
    if [ "$active_user" != "root" ] && [ -n "$user_id" ]; then
        launchctl asuser "$user_id" sudo -u "$active_user" osascript -e "display notification \"$message\" with title \"Установка ПО\""
    fi
}
# Проверяем, установлен ли office
if [ -d "/Applications/Microsoft Outlook.app" ] || [ -d "/Applications/Microsoft Excel.app" ]; then
    echo "Microsoft Office уже установлен."
    exit 0
else
	# https://learn.microsoft.com/en-us/officeupdates/update-history-office-for-mac
	filename="/opt/Microsoft_365_and_Office_16.94.25020927_Installer.pkg"
	url="https://officecdn.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/Microsoft_365_and_Office_16.94.25020927_Installer.pkg"

	show_notification "Загрузка программного обеспечения..."
	echo "Загрузка программного обеспечения..."
	if curl -L "$url" -o "$filename"; then
		chmod +x "$filename"
		show_notification "Началась установка программного обеспечения..."
		echo "Началась установка программного обеспечения..."
		if sudo installer -pkg "$filename" -target /; then
			show_notification "Установка завершена успешно."
			sudo rm -f "$filename"
	  echo "Установка завершена успешно."
		else
			show_notification "Ошибка при установке."
	  echo "Ошибка при установке"
		fi
	else
		#show_notification "Ошибка при загрузке файла."
		echo "Ошибка при загрузке файла."
	fi
	filename="/opt/Microsoft_Office_LTSC_2021_VL_Serializer.pkg"
	url="YOUR URL TO PKG FILE Serializer"

	show_notification "Загрузка программного обеспечения..."
	echo "Загрузка программного обеспечения..."
	if curl -L "$url" -o "$filename"; then
		chmod +x "$filename"
		show_notification "Началась установка программного обеспечения..."
		echo "Началась установка программного обеспечения..."
		if sudo installer -pkg "$filename" -target /; then
			show_notification "Установка завершена успешно."
			sudo rm -f "$filename"
	  echo "Установка завершена успешно."
		else
			show_notification "Ошибка при установке."
	  echo "Ошибка при установке"
		fi
	else
		#show_notification "Ошибка при загрузке файла."
		echo "Ошибка при загрузке файла."
	fi
fi

# Проверяем, установлен ли агент kes
if command -v pkgutil &>/dev/null && pkgutil --pkgs | grep -q "com.kaspersky.kav.core"; then
    #show_notification "kes уже установлен. Установка не требуется."
    echo "kes уже установлен. Установка не требуется."
else
	filename="/opt/kesmac12.1.0.553.sh"
	url="You file URL"

	show_notification "Загрузка программного обеспечения..."
	echo "Загрузка программного обеспечения..."
	if curl -L "$url" -o "$filename"; then
		chmod +x "$filename"
		show_notification "Началась установка программного обеспечения..."
		echo "Начата Началась программного обеспечения..."    
		if "$filename"; then
			show_notification "Установка завершена успешно."
		echo "Установка завершена успешно."
		sudo rm -f "$filename"
		else
			show_notification "Ошибка при установке."
		echo "Ошибка при установке"
		fi
	else
		#show_notification "Ошибка при загрузке файла."
		echo "Ошибка при загрузке файла."
	fi
fi

# Проверяем, установлен ли агент klagent
if command -v pkgutil &>/dev/null && pkgutil --pkgs | grep -q "com.kaspersky.klnagent.core"; then
    #show_notification "klnagent уже установлен. Установка не требуется."
    echo "klnagent уже установлен. Завершаем скрипт."
else
	filename="/opt/klnagentmac.sh"
	url="You file URL"

	show_notification "Загрузка программного обеспечения..."
	echo "Загрузка программного обеспечения..."
	if curl -L "$url" -o "$filename"; then
		chmod +x "$filename"
		show_notification "Началась установка программного обеспечения..."
		echo "Началась установка программного обеспечения..."
		if "$filename"; then
			show_notification "Установка завершена успешно."
		echo "Установка завершена успешно."
		sudo rm -f "$filename"
		else
			show_notification "Ошибка при установке."
		echo  "Ошибка при установке."
		fi
	else
		#show_notification "Ошибка при загрузке файла."
		echo  "Ошибка при загрузке файла."
	fi
fi

PRINTER_NAME="SafeQKM"
PRINTER_URL="smb://YOURDOMAIN.com/SafeQKM"
PPD_PATH="/Library/Printers/PPDs/Contents/Resources/KONICAMINOLTAC450i.gz"

# Определяем текущий принтер по умолчанию
DEFAULT_PRINTER=$(lpstat -d 2>/dev/null | awk '{print $NF}')

# Если принтер уже установлен по умолчанию, выходим
if [[ "$DEFAULT_PRINTER" == "$PRINTER_NAME" ]]; then
    echo "Принтер уже установлен по умолчанию."
else

	# Добавляем принтер
	echo "Устанавливаем принтер $PRINTER_NAME..."
	lpadmin -p "$PRINTER_NAME" -E -L "prn" -D "SafeQ на PRN" -o printer-is-shared=false -v "$PRINTER_URL" -P "$PPD_PATH"

	# Устанавливаем принтер по умолчанию
	lpoptions -d "$PRINTER_NAME"

	# Проверяем успешность установки
	if lpstat -p "$PRINTER_NAME" &>/dev/null; then
		echo "Принтер $PRINTER_NAME успешно добавлен и установлен по умолчанию!"
	else
		echo "Ошибка при добавлении принтера."
		exit 1
	fi
fi

plistBuddy='/usr/libexec/PlistBuddy'
GPplistFile='/Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist'
DownloadLocation='YOUR URL location'

if [ -f ${GPplistFile} ]
then
  echo "Plist already exists..."
else
  echo "Creating Plist"
  ${plistBuddy} -c "print : 'Palo Alto 
Networks':'GlobalProtect':'PanSetup':'Portal'" ${GPplistFile}
  ${plistBuddy} -c "add :'Palo Alto Networks' dict" ${GPplistFile}
  ${plistBuddy} -c "add :'Palo Alto Networks':'GlobalProtect' dict" ${GPplistFile}
  ${plistBuddy} -c "add :'Palo Alto 
Networks':'GlobalProtect':'PanSetup' dict" ${GPplistFile}
  ${plistBuddy} -c "add :'Palo Alto 
Networks':'GlobalProtect':'PanSetup':'Portal' string 'vpn.qiwi.com'" ${GPplistFile}
  ${plistBuddy} -c "add :'Palo Alto 
Networks':'GlobalProtect':'PanSetup':'Prelogon' integer 0" ${GPplistFile}
fi
  
if [ -d "/Applications/GlobalProtect.app" ]
then
  echo "Already installed..."
  exit 0
else
  echo "Preparing..."
  curl -L ${DownloadLocation} > "/tmp/GlobalProtect.pkg"
  echo "Installing..."  
  sudo installer -pkg "/tmp/GlobalProtect.pkg" -target /
  exit 0
fi
