## DESCRIPTION
This script creates a set of 1-4 Windows Server 2016 VMs with Network Security Groups for RDP access. In this script, these machines will be deployed using the ABC[DC]## convention, where ABC is the 3 letter airport code of the location, DC indicates that these machines can subsequently be configured as domain controllers, and ## represents the sequence numbers, i.e. 01, 02, etc. Azure resources will be created as part of an initial process of building a functional environment consisting of compute, storage and netorking components. Since this script will be used primarily for demonstration purposes, additional comments, logging and verbose console output have also been included.

REQUIREMENTS:
1. A Windows Azure subscription

2. Windows OS (Windows 7/Windows Server 2008 R2 or greater)

3. Windows Management Foundation (WMF 5.0 or greater installed to support PowerShell 5.0 or higher version)
   [link](https://docs.microsoft.com/en-us/powershell/wmf/readme)

FEEDBACK
Feel free to ask questions, provide feedback, contribute, file issues, etc. so we can make this even better!