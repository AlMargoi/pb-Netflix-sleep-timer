
# CSource Implementation got from: https://stackoverflow.com/questions/39353073/how-i-can-send-mouse-click-in-powershell

$cSource = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker
{
//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646270(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct INPUT
{ 
    public int        type; // 0 = INPUT_MOUSE,
                            // 1 = INPUT_KEYBOARD
                            // 2 = INPUT_HARDWARE
    public MOUSEINPUT mi;
}

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646273(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct MOUSEINPUT
{
    public int    dx ;
    public int    dy ;
    public int    mouseData ;
    public int    dwFlags;
    public int    time;
    public IntPtr dwExtraInfo;
}

//This covers most use cases although complex mice may have additional buttons
//There are additional constants you can use for those cases, see the msdn page
const int MOUSEEVENTF_MOVED      = 0x0001 ;
const int MOUSEEVENTF_LEFTDOWN   = 0x0002 ;
const int MOUSEEVENTF_LEFTUP     = 0x0004 ;
const int MOUSEEVENTF_RIGHTDOWN  = 0x0008 ;
const int MOUSEEVENTF_RIGHTUP    = 0x0010 ;
const int MOUSEEVENTF_MIDDLEDOWN = 0x0020 ;
const int MOUSEEVENTF_MIDDLEUP   = 0x0040 ;
const int MOUSEEVENTF_WHEEL      = 0x0080 ;
const int MOUSEEVENTF_XDOWN      = 0x0100 ;
const int MOUSEEVENTF_XUP        = 0x0200 ;
const int MOUSEEVENTF_ABSOLUTE   = 0x8000 ;

const int screen_length = 0x10000 ;

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310(v=vs.85).aspx
[System.Runtime.InteropServices.DllImport("user32.dll")]
extern static uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

public static void LeftClickAtPoint(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    //Left mouse button down
    input[1].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    //Left mouse button up
    input[2].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(3, input, Marshal.SizeOf(input[0]));
}
}
'@
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing

#region Function Definition
function Get-UserInput{
    param (
        [Parameter(Mandatory=$true)]
        [string] $UserPrompt,


        [Parameter(Mandatory=$true)]
        [ValidateSet('string','int')]
        [string] $DataType,

        [Parameter(Mandatory=$false)]
        $DataValidation
    )

    $Reprompt = $true
    $Prompt = $UserPrompt
    while($Reprompt){
        $UserInput = Read-Host -Prompt $Prompt
        if($DataType -eq "int"){
            try{
                $ConvertedUserInput = [int]$UserInput
                if(!$DataValidation){
                    $Reprompt = $false
                }
            }catch{
                $Prompt = $UserPrompt + " (must be an integer [CTRL + C to break out of the loop])"
            }
        }elseif($DataType -eq "string"){
            # Do nothing - left open for future possible uses
        }else{
            # This branch should not be reached because of the ValidateSet
        }

        if($DataValidation){
            if($DataValidation.GetType().Name -eq 'Object[]'){
                if($DataValidation.ToLower().Contains($UserInput.ToLower())){
                    $Reprompt = $false
                }else{
                    $Prompt =  $UserPrompt + "(must be one of the following: $DataValidation)"
                }
            }else{
                if($DataValidation.ToLower() -eq $UserInput.ToLower()){
                    $Reprompt = $false
                }else{
                    $Prompt =  $UserPrompt + "(must be one of the following: $DataValidation)"
                }
            }
        }
    }

    return $UserInput
}
#endregion


$minutes = Get-UserInput -UserPrompt "How many minutes would you like to sleep?" -DataType "int"
$shutdown = (Get-UserInput -UserPrompt "Do you also want to shutdown PC after sleep? [y/n]" -DataType "string" -DataValidation @("y", "n")).ToLower()
if($shutdown -eq "y"){
	$minutesToShutdown = Get-UserInput -UserPrompt "How many additional minutes should I wait before shutting down? (0 is default)" -DataType "int"
}
Start-Sleep -Seconds (60*$minutes)
[Clicker]::LeftClickAtPoint(500,500)
if($shutdown -eq "y"){
    if($minutesToShutdown -eq "$null"){
        continue
    }else{
        start-sleep -Seconds ($minutesToShutdown*60)
    }
    shutdown /s /t 0
}