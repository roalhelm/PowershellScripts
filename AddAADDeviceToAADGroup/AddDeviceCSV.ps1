<#
.SYNOPSIS
    Creates a CSV file containing a list of device names entered through a GUI. 
    The device names can be separated by spaces, commas, or semicolons.

.DESCRIPTION
    This script provides a graphical user interface (GUI) to enter a list of device names. 
    The device names are processed, and a CSV file named 'Devices.csv' is created. 
    The CSV file will contain a single column titled 'DeviceName' without quotation marks 
    around the names. The user can separate the names with spaces, commas, or semicolons.

.NOTES
    File Name      : CreateDeviceCSV.ps1
    Author         : Ronny Alhelm
    Version        : 1.0
    Creation Date  : 2025-03-12
    Last Modified  : 2025-03-12
    Requirements   : PowerShell 5.1 or higher
    Dependencies   : System.Windows.Forms, System.Drawing

.AUTHOR
    Ronny Alhelm

.VERSION
    1.0 - Initial version.

.EXAMPLE
    PS C:\> .\CreateDeviceCSV.ps1
    This command will open the GUI. After entering the device names separated by commas, 
    spaces, or semicolons, clicking "Create CSV" will generate the 'Devices.csv' file in 
    the same directory.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Device CSV Creator"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# TextBox for entering device names
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Width = 350
$textBox.Height = 100
$textBox.Location = New-Object System.Drawing.Point(20, 20)

# Button to create the CSV
$button = New-Object System.Windows.Forms.Button
$button.Text = "Create CSV"
$button.Width = 100
$button.Height = 30
$button.Location = New-Object System.Drawing.Point(150, 150)

# Event handler for the button
$button.Add_Click({
    # Get the input from the TextBox
    $input = $textBox.Text
    
    # Split the device names by spaces, commas, or semicolons
    $deviceNames = $input -split '[,; \r\n]+'

    # Prepare the CSV file (without quotes)
    $csvPath = "Devices.csv"
    
    # Create the CSV file with the header
    "DeviceName" | Out-File -FilePath $csvPath -Encoding UTF8
    
    # Write the device names into the CSV file without quotes
    $deviceNames | ForEach-Object {
        $_ | Out-File -FilePath $csvPath -Encoding UTF8 -Append
    }

    [System.Windows.Forms.MessageBox]::Show("CSV has been created: $csvPath")
})

# Button to close the window
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Width = 100
$closeButton.Height = 30
$closeButton.Location = New-Object System.Drawing.Point(150, 200)
$closeButton.Add_Click({$form.Close()})

# Add controls to the form
$form.Controls.Add($textBox)
$form.Controls.Add($button)
$form.Controls.Add($closeButton)

# Show the form
$form.ShowDialog()
