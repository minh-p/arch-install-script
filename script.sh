#!/bin/bash
#part1
# Inspired by Bugswriter's arch install script :). As well as copied (for some)
printf '\033c'
echo "Welcome to the Minh's Arch install script."
# Speed up downloading
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
# loadkeys
loadkeys us
# synchronize time
timedatectl set-ntp true
# Setting up partitioning
lsblk
echo "Enter drive name (ex: sda): "
read drive
fdisk /dev/$drive
echo "Nice! You have finished creating all the partitions!"
lsblk
echo "Now, enter your root partition name (ex: sda4): "
read root_partition
mkfs.ext4 /dev/$root_partition
mount /dev/$root_partition /mnt
# For home partition
read -p "Did you also create home partition? [y/n] " answer
if [[ $answer = y ]] ; then
    lsblk
    echo "Enter Home partition name (ex: sda5): "
    read home_partition
    mkfs.ext4 /dev/$home_partition
    mkdir /mnt/home
    mount /dev/$home_partition /mnt/home
fi
# For EFI
read -p "Did you also create efi partition? [y/n] " answer
if [[ $answer = y ]] ; then
    lsblk
    echo "Enter EFI partition: "
    mkdir -p /mnt/boot/EFI
    read efi_partition
    mkfs.vfat -F 32 /dev/$efi_partition
    mount /dev/$efi_partition /mnt/boot/EFI
fi
# pacstrap
echo "We are moving on to pacstrapping"
read -p "What is your editor of choice? " editor
echo "Pacstrapping..."
pacstrap /mnt base base-devel linux linux-firmware linux-headers $editor
# genfstab
genfstab -U /mnt >> /mnt/etc/fstab
# Moving onto the next part
sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt
./arch_install2.sh
#part2
printf '\033c'
echo "We are on the second part of the install guide!"
pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
# timezone
ls /usr/share/zoneinfo
echo "Enter your region: "
read region
ls /usr/share/zoneinfo/$region
echo "Enter your city: "
read city
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc
# locale or language
cat /etc/locale.gen
echo "Enter locale language choice: "
read locacle_choice
echo $locacle_choice >> /etc/locale.gen
echo "Enter option for LANG, LC_MESSAGES. Ex: en_US.UTF-8 not en_US.UTF-8 UTF-8"
read lang
echo LANG=$lang > /etc/locale.conf
echo LC_MESSAGES=$lang >> /etc/locale.conf
locale-gen
echo "Enter keymap (ex: us): "
read keymap
echo "KEYMAP=$keymap" > /etc/vconsole.conf
#hostname
echo "Next up, what is your hostname? "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
# root password
echo "Next, enter your root password"
passwd
pacman --noconfirm -S grub efibootmgr os-prober
# boot option
echo "We are going to configure GRUB bootloader"
echo "What is your drive's name again?"
read drive
read -p "Are you booting on UEFI? [y/n] " answer
if [[ $answer = y ]] ; then
    grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
    sed -i 's/quiet/pci=noaer/g' /etc/default/grub
fi
if [[ $answer = n ]] ; then
    grub-install --target=i386-pc /dev/$drive
fi
echo "What is your cpu brand? (ex: intel)"
read cpu_brand
pacman -S $cpu_brand-ucode
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
# downloading necessary packages
echo "Next, downloading the packages!"
echo "First, enable multilib"
echo "[multilib]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
pacman -Sy
sleep 5
pacman -S --noconfirm xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop \
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-dejavu ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     sxiv mpv zathura zathura-pdf-mupdf ffmpeg imagemagick  \
     fzf man-db xwallpaper python-pywal unclutter xclip maim \
     zip unzip unrar p7zip xdotool papirus-icon-theme brightnessctl  \
     dosfstools ntfs-3g git sxhkd zsh pipewire pipewire-pulse pipewire-alsa \
     emacs alsa-utils arc-gtk-theme rsync qutebrowser \
     xcompmgr libnotify dunst slock jq aria2 cowsay \
     dhcpcd connman wpa_supplicant rsync pamixer mpd ncmpcpp \
     zsh-syntax-highlighting xdg-user-dirs libconfig \
     bluez bluez-utils alacritty man-pages reflector redshift firefox nitrogen \
     mesa networkmanager starship htop neofetch discord timidity mesa-utils \
     deepin-screenshot feh polkit xf86-input-synaptics yt-dlp mpc tmux thunar \
     bashtop rust fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-unikey sway
# enable network
echo "Enabling NetworkManager in systemd"
sleep 3
systemctl enable NetworkManager
# groups and sudo permission
echo "Setting groups and sudo permission"
echo "root ALL=(ALL) ALL" >> /etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo "Enter your username: "
read username
useradd -m -G wheel -s /bin/bash $username
echo "Enter the password for $username"
passwd $username
# post installation/third part setup
echo "Pre-Installation Finish Reboot now"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/bash $username
exit
#part3
printf '\033c'
cd $HOME
nmtui
read -p "Would you like to continue this script post-installation stage? [y/n] " answer
if [[ $answer = n ]] ; then
    exit
fi
# dotfiles
echo "Enter your user password"
read password
echo "Enter your username"
read username
read -p "Do you have a git repo for dot files? [y/n] " answer
if [[ $answer = y ]] ; then
    echo "Enter your git repo link or path (BE SURE to add .git; ex: https://github.com/user/dotfiles.git)"
    read git_repo_path
    git clone --separate-git-dir=$HOME/dotfiles "$git_repo_path" tmpdotfiles
    rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
    rm -rf tmpdotfiles
fi
# dwm: Window Manager
read -p "Do you have a dwm git repo? [y/n] " answer
if [[ $answer = y ]] ; then
    echo "Enter your git repo link or path for dwm"
    read dwm_git_repo_path
    git clone --depth=1 "$dwm_git_repo_path" ~/.local/src/dwm
    echo $password | sudo -S make -C ~/.local/src/dwm install
fi
# dmenu: launcher
read -p "Do you have a dmenu git repo? [y/n] " answer
if [[ $answer = y ]] ; then
    echo "Enter your git repo link or path for dmenu"
    read dmenu_git_repo_path
    git clone --depth=1 "$dmenu_git_repo_path" ~/.local/src/dmenu
    echo $password | sudo make -S -C ~/.local/src/dmenu install
fi
# dwmblocks: dwm modular statusbar
read -p "Do you have a dwmblocks git repo? [y/n] " answer
if [[ $answer = y ]] ; then
    echo "Enter your git repo link or path for dwmblocks"
    read dwmblocks_git_repo_path
    git clone --depth=1 "$dwmblocks_git_repo_path" ~/.local/src/dwmblocks
    sudo make -C ~/.local/src/dwmblocks install
fi
# gpu drivers for Open source only
read -p "Would you like to download open-source gpu driver [y/n] " answer
if [[ $answer = y ]] ; then
    echo "Enter your gpu driver's name (ex: xf86-video-nouveau or xf86-video-amdgpu)"
    echo "xf86-video-nouveau"
    echo "xf86-video-amdgpu"
    echo "xf86-video-ati"
    echo "xf86-video-intel"
    read gpu_driver
    echo $password | sudo -S pacman -S $gpu_driver
fi
if [[ $answer = n ]] ; then
    echo "You are going to have to configure GPU on your own!"
fi
echo "Regardless, you are going to have to configure gpu stuff! Sorry :("
# view autostart to install what is left needed
read -p "Would you like to view your autostart file? [y/n]" answer
if [[ $answer = y ]] ; then
    echo "Enter your autostart file path (ex: /home/user/.config/autostart)"
    read autostart_path
    echo "Check out your autostart file! You should have all of these things installed:"
    cat $autostart_path
fi

# aur packages
git clone https://aur.archlinux.org/pikaur.git ~/.local/src/
cd ~/.local/src/pikaur
makepkg -fsri
cd
pikaur -S lua-language-server ani-cli picom-git nerd-fonts-complete pacmixer mpd-rich-presence-discord-git \
    betterlockscreen noto-fonts-main wob sov

systemctl enable betterlockscreen@$USER

# config dots
cd /home/$username
git clone https://github.com/minh-p/MinimalNvim .config/nvim
git clone https://github.com/minh-p/emacs_config .config/emacs
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
cargo install mpd-discord-rpc
exit
