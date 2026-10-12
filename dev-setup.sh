#!/bin/bash
# This script is used to quickly install and remove development packages (meson, ninja-build, valac, libgtk-3-dev, libgranite-dev, libgee-0.8-dev, libjson-glib-dev, libportal-dev, libportal-gtk3-dev) required for GTK/Vala desktop application development on Linux.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to install packages
install_packages() {
    print_message "Starting package installation..."
    
    # Update repository
    print_message "Updating repository..."
    sudo apt update
    
    # Install packages
    print_message "Installing meson and ninja-build..."
    sudo apt install -y meson ninja-build
    
    print_message "Installing valac, libgtk-3-dev, libgranite-dev, libgee-0.8-dev, libjson-glib-dev, libportal-dev, libportal-gtk3-dev..."
    sudo apt install -y valac libgtk-3-dev libgranite-dev libgee-0.8-dev libjson-glib-dev libportal-dev libportal-gtk3-dev
    
    # Check installation status
    if [ $? -eq 0 ]; then
        print_message "Installation completed!"
        echo ""
        print_message "Installed versions:"
        meson --version 2>/dev/null || echo "meson: not installed"
        ninja --version 2>/dev/null || echo "ninja: not installed"
        valac --version 2>/dev/null || echo "valac: not installed"
    else
        print_error "An error occurred during installation!"
        exit 1
    fi
}

# Function to uninstall packages
uninstall_packages() {
    print_warning "Starting package uninstallation..."
    
    # Confirmation before uninstall
    echo -e "${YELLOW}Are you sure you want to remove the following packages?${NC}"
    echo "  - meson"
    echo "  - ninja-build"
    echo "  - valac"
    echo "  - libgtk-3-dev"
    echo "  - libgranite-dev"
    echo "  - libgee-0.8-dev"
    echo "  - libjson-glib-dev"
    echo "  - libportal-dev"
    echo "  - libportal-gtk3-dev"
    echo ""
    read -p "Continue? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Uninstall packages
        print_message "Removing packages..."
        sudo apt remove --purge -y meson ninja-build valac libgtk-3-dev libgranite-dev libgee-0.8-dev libjson-glib-dev libportal-dev libportal-gtk3-dev
        
        # Remove unnecessary dependencies
        print_message "Cleaning up unnecessary dependencies..."
        sudo apt autoremove -y
        
        # Clean cache
        print_message "Cleaning cache..."
        sudo apt autoclean
        
        print_message "Uninstallation completed!"
    else
        print_message "Uninstallation cancelled."
    fi
}

# Function to check package status
check_status() {
    print_message "Checking package status..."
    echo ""
    
    echo "Package Status:"
    echo "--------------"
    
    # Check each package
    for pkg in meson ninja-build valac libgtk-3-dev libgranite-dev libgee-0.8-dev libportal-dev libportal-gtk3-dev; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            echo -e "${GREEN}✓${NC} $pkg: installed"
        else
            echo -e "${RED}✗${NC} $pkg: not installed"
        fi
    done
}

# Function to configure build directory
build_project() {
    print_message "Configuring build directory with meson..."
    if [ -d "build" ]; then
        read -p "Build directory exists. Reconfigure? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            meson setup --reconfigure build
        else
            print_message "Skipped."
            return
        fi
    else
        meson setup build
    fi
    
    if [ $? -eq 0 ]; then
        print_message "Build configured successfully!"
    else
        print_error "Meson configuration failed!"
        exit 1
    fi
}

# Function to compile project
compile_project() {
    if [ ! -d "build" ]; then
        print_error "Build directory not found! Run 'Build (meson setup)' first."
        return
    fi
    
    print_message "Compiling project..."
    meson compile -C build
    if [ $? -eq 0 ]; then
        print_message "Compilation successful!"
    else
        print_error "Compilation failed!"
        exit 1
    fi
}

# Function to install project
install_project() {
    if [ ! -d "build" ]; then
        print_error "Build directory not found! Run 'Build (meson setup)' first."
        return
    fi
    
    print_message "Installing project to system..."
    sudo ninja -C build install
    if [ $? -eq 0 ]; then
        print_message "Installation successful!"
    else
        print_error "Installation failed!"
        exit 1
    fi
}

# Function to uninstall project
uninstall_project() {
    # Pick the build dir whose install actually exists on disk (build-user => ~/.local, build => /usr/local)
    local dir="" prefix=""
    for d in build-user build; do
        [ -f "$d/meson-private/install.dat" ] || continue
        local p=$(sed -n 's/^prefix = //p' "$d/meson-private/cmd_line.txt" 2>/dev/null)
        if [ -x "${p:-/usr/local}/bin/com.github.gylangsatria.clipstory" ]; then
            dir="$d"; prefix="$p"; break
        fi
        [ -z "$dir" ] && { dir="$d"; prefix="$p"; }
    done

    if [ -z "$dir" ]; then
        print_error "No configured build directory found! Run 'Build (meson setup)' first."
        return
    fi

    print_warning "This will remove ClipStory files from prefix: ${prefix:-/usr/local} (build dir: $dir)."
    read -p "Continue? (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "Uninstalling project from system..."
        # Only need sudo when the prefix is a system location
        local sudo_cmd=""
        [[ "$prefix" == /usr* ]] && sudo_cmd="sudo"
        $sudo_cmd ninja -C "$dir" uninstall
        if [ $? -eq 0 ]; then
            # Refresh schema cache so the removed schema is dropped
            local schemas="${prefix:-/usr}/share/glib-2.0/schemas"
            $sudo_cmd glib-compile-schemas "$schemas" 2>/dev/null
            print_message "Uninstallation finished!"
        else
            print_error "Uninstallation failed!"
            exit 1
        fi
    else
        print_message "Uninstallation cancelled."
    fi
}

# Function to build .deb package
build_deb() {
    print_message "Starting .deb package build..."
    
    # Check if build directory exists, if not configure it
    if [ ! -d "build" ]; then
        print_message "Configuring build directory with meson..."
        meson setup build
        if [ $? -ne 0 ]; then
            print_error "Meson configuration failed!"
            exit 1
        fi
    fi
    
    # Compile project
    print_message "Compiling project..."
    meson compile -C build
    if [ $? -ne 0 ]; then
        print_error "Compilation failed!"
        exit 1
    fi
    print_message "Compilation successful!"
    
    # Install to staging directory
    print_message "Installing to deb-package staging directory..."
    DESTDIR="$PWD/deb-package" meson install -C build
    if [ $? -ne 0 ]; then
        print_error "Install to staging failed!"
        exit 1
    fi
    
    # Build .deb package
    print_message "Building .deb package..."
    # dpkg-deb requires the control file to end with a newline
    [ -n "$(tail -c1 deb-package/DEBIAN/control)" ] && printf '\n' >> deb-package/DEBIAN/control
    dpkg-deb --build deb-package/
    if [ $? -ne 0 ]; then
        print_error "Failed to build .deb package!"
        exit 1
    fi
    
    # Rename .deb file with version
    local version=$(grep '"version"' build/meson-info/intro-projectinfo.json 2>/dev/null | sed 's/.*: *"\(.*\)".*/\1/' || echo "1.4.2")
    local deb_file="clipboard-history_${version}_amd64.deb"
    mv deb-package.deb "$deb_file"
    
    if [ -f "$deb_file" ]; then
        print_message "Build complete! Package created: $deb_file"
        ls -lh "$deb_file"
    else
        print_error "Package file not found!"
        exit 1
    fi
}

# Main menu
show_menu() {
    echo "========================================"
    echo "  ClipStory - Dev Tools"
    echo "========================================"
    echo " 1. Install packages"
    echo " 2. Uninstall packages"
    echo " 3. Check package status"
    echo "----------------------------------------"
    echo " 4. Build (meson setup)"
    echo " 5. Compile (meson compile)"
    echo " 6. Install (sudo ninja install)"
    echo " 7. Uninstall (sudo ninja uninstall)"
    echo "----------------------------------------"
    echo " 8. Build .deb package"
    echo " 9. Exit"
    echo "========================================"
}

# Main script
main() {
    # Check if running as root directly
    if [ "$EUID" -eq 0 ]; then 
        print_error "Do not run this script as root directly!"
        print_error "Use a regular user with sudo access."
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Select option (1-9): " choice
        
        case $choice in
            1)
                install_packages
                ;;
            2)
                uninstall_packages
                ;;
            3)
                check_status
                ;;
            4)
                build_project
                ;;
            5)
                compile_project
                ;;
            6)
                install_project
                ;;
            7)
                uninstall_project
                ;;
            8)
                build_deb
                ;;
            9)
                print_message "Thank you, exiting script..."
                exit 0
                ;;
            *)
                print_error "Invalid option!"
                ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Run main function
main