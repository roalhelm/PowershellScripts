<#
.SYNOPSIS
    Creates a CSV file containing a list of device names entered through a GUI.
    The GUI also displays the current contents of the CSV file.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script provides a graphical user interface (GUI) to enter a list of device names.
    The names can be separated by spaces, commas, or semicolons.
    The script creates a CSV file named 'Devices.csv' with a single column 'DeviceName' 
    and updates a second text box to display the current content of the CSV file.

.NOTES
    File Name      : CreateDeviceCSV.ps1
    Author         : Ronny Alhelm
    Version        : 1.2
    Creation Date  : 2025-03-12
    Last Modified  : 2025-04-29
    Requirements   : PowerShell 5.1 or higher
    Dependencies   : System.Windows.Forms, System.Drawing

.CHANGES
    v1.0 - 2025-03-12 - Initial release
    v1.1 - 2025-03-12 - Added CSV display functionality
    v1.2 - 2025-03-13 - Updated layout to display input and output side by side
    v1.3 - 2025-04-28 - Added AAD group integration functionality
    v1.4 - 2025-04-29 - Updated button layout and improved UI alignment

.VERSION
    1.4 - Updated button layout and improved UI alignment.

.EXAMPLE
    PS C:\> .\CreateDeviceCSV.ps1
    This command will open the GUI. After entering device names and clicking
    "Create CSV", the script will generate a 'Devices.csv' file and show its content.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load external function script
. "$PSScriptRoot\Add-DevicesToAADGroupFunction.ps1"

# Function to load CSV content into the output text box
function Load-CSVContent {
    if (Test-Path "$PSScriptRoot\Devices.csv") {
        $csvContent = Get-Content "$PSScriptRoot\Devices.csv" -Raw
        $outputBox.Text = $csvContent
    } else {
        $outputBox.Text = "No CSV file found."
    }
}

# Create the GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Device CSV Creator"
$form.Size = New-Object System.Drawing.Size(700, 400)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Label for input box
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = "1. Enter Device Names (comma, semicolon, or space-separated):"
$inputLabel.AutoSize = $true
$inputLabel.Location = New-Object System.Drawing.Point(20, 10)

# TextBox for entering device names (left side)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Width = 300
$textBox.Height = 150
$textBox.Location = New-Object System.Drawing.Point(20, 30)

# Label for output box
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = "Current CSV Content:"
$outputLabel.AutoSize = $true
$outputLabel.Location = New-Object System.Drawing.Point(350, 10)

# TextBox to display the current CSV file content (right side)
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.Width = 300
$outputBox.Height = 150
$outputBox.Location = New-Object System.Drawing.Point(350, 30)
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = "Vertical"

# Calculate center positions for buttons
$totalButtonWidth = 260  # 120 + 20 + 120 (two buttons plus spacing)
$startX = ($form.ClientSize.Width - $totalButtonWidth) / 2

# Button to create the CSV (centered)
$button = New-Object System.Windows.Forms.Button
$button.Text = "2. Create CSV"
$button.Width = 120
$button.Height = 30
$button.Location = New-Object System.Drawing.Point($startX, 190)

# Button to cleanup the CSV file (centered)
$cleanupButton = New-Object System.Windows.Forms.Button
$cleanupButton.Text = "5. Cleanup CSV"
$cleanupButton.Width = 120
$cleanupButton.Height = 30
$cleanupButton.Location = New-Object System.Drawing.Point(($startX + 140), 190)

# Label for group name input (moved down)
$groupLabel = New-Object System.Windows.Forms.Label
$groupLabel.Text = "3. Azure AD Group Name:"
$groupLabel.AutoSize = $true
$groupLabel.Location = New-Object System.Drawing.Point(20, 230)

# TextBox for group name input (moved down)
$groupTextBox = New-Object System.Windows.Forms.TextBox
$groupTextBox.Width = 200
$groupTextBox.Height = 20
$groupTextBox.Location = New-Object System.Drawing.Point(20, 250)

# Add to Group button (moved down)
$addToGroupButton = New-Object System.Windows.Forms.Button
$addToGroupButton.Text = "4. Add to AAD Group"
$addToGroupButton.Width = 120
$addToGroupButton.Height = 30
$addToGroupButton.Location = New-Object System.Drawing.Point(230, 245)

# Button to close the window (moved down)
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Width = 120
$closeButton.Height = 30
$closeButton.Location = New-Object System.Drawing.Point(400, 290)
$closeButton.Add_Click({ $form.Close() })

# Event handler for the button
$button.Add_Click({
    # Get input from the TextBox
    $input = $textBox.Text
    
    # Split the device names by spaces, commas, or semicolons
    $deviceNames = $input -split '[,; \r\n]+'

    # Prepare the CSV file (without quotes)
    $csvPath = "$PSScriptRoot\Devices.csv"
    
    # Create the CSV file with the header
    "DeviceName" | Out-File -FilePath $csvPath -Encoding UTF8
    
    # Write the device names into the CSV file without quotes
    $deviceNames | ForEach-Object {
        $_ | Out-File -FilePath $csvPath -Encoding UTF8 -Append
    }

    # Reload the CSV content into the output box
    Load-CSVContent

    [System.Windows.Forms.MessageBox]::Show("CSV has been created: $csvPath")
})

# Event handler for the cleanup button
$cleanupButton.Add_Click({
    if (Test-Path "$PSScriptRoot\Devices.csv") {
        # Create new CSV with only the header
        "DeviceName" | Out-File -FilePath "$PSScriptRoot\Devices.csv" -Encoding UTF8 -Force

        # Reload the CSV content
        Load-CSVContent
        
        # Clear the input textbox
        $textBox.Clear()
        
        [System.Windows.Forms.MessageBox]::Show("CSV file has been cleared. All devices have been removed.")
    } else {
        [System.Windows.Forms.MessageBox]::Show("No CSV file found to clean up.")
    }
})

# Add event handler for Add to Group button
$addToGroupButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($groupTextBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter an Azure AD group name.", "Error")
        return
    }

    try {
        $result = Add-DevicesToAADGroup -GroupName $groupTextBox.Text -CsvPath "$PSScriptRoot\Devices.csv"

        # Create summary message
        $summary = @"
Operation completed:
Successfully added: $($result.Success)
Already members: $($result.AlreadyMember)
Not found: $($result.NotFound)
Failed: $($result.Failed)

Log files:
$($result.LogFile)
$($result.ErrorLogFile)
"@

        if ($result.Failed -eq 0 -and $result.NotFound -eq 0) {
            [System.Windows.Forms.MessageBox]::Show($summary, "Success")
        } else {
            [System.Windows.Forms.MessageBox]::Show("$summary`n`nSome operations failed. Check error log for details.", "Warning")
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $_", "Error")
    }
})

# Load CSV content initially
Load-CSVContent

# Add controls to the form
$form.Controls.Add($inputLabel)
$form.Controls.Add($textBox)
$form.Controls.Add($outputLabel)
$form.Controls.Add($outputBox)
$form.Controls.Add($button)
$form.Controls.Add($cleanupButton)
$form.Controls.Add($closeButton)
$form.Controls.Add($groupLabel)
$form.Controls.Add($groupTextBox)
$form.Controls.Add($addToGroupButton)

# Show the form
$form.ShowDialog()
