# GPU Auto Switch (Windows)

Automatically disables NVIDIA GPU on battery (when idle) and enables it
on AC power.

## Features

-   Auto-detects NVIDIA GPU
-   Prevents disabling while GPU is in use
-   Works with charge limiters
-   Uses reliable Windows events + fallback polling

## Requirements

-   Windows 10/11
-   NVIDIA drivers installed
-   Run as Administrator

## Installation

1.  Download the `.bat` file
2.  Right-click → Run as Administrator

## Tasks Created

-   GPU AutoSwitch - Disable (Event)
-   GPU AutoSwitch - Enable (Event)
-   GPU AutoSwitch - Disable (Idle Check)

## Notes

-   Uses `nvidia-smi` for accurate GPU usage
-   Uses multiple power event IDs for compatibility
-   Safe to run multiple times

## Uninstall

Delete the created tasks in Task Scheduler.
