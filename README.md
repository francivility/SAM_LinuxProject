# SAM_LinuxProject

  _This repository contains the documentation, automated scripts, and deployment plans for a comprehensive System Administration project. The primary objective is to transition a client organization from an unsecured, vulnerable file system into a protected, organized, and recoverable infrastructure without relying on custom web applications or databases._

# **_Phase 1: Problem Assessment and OS Selection_**
  -Identify a real, reachable organization and document their current IT vulnerabilities, specifically regarding access control and data loss risks.  
  -Select and provide a formal justification for a server operating system.  
  -_**Deliverables:**_ Interview notes, photos of the current setup, a written problem statement, and the OS justification.  

# **_Phase 2: Installation and Security Implementation_**
  -Install the chosen operating system (e.g., via VirtualBox) and create user accounts directly mapped to actual staff roles.  
  -Implement strict access controls by configuring specific users, groups, and folder permissions to segment confidential data.  
  -**_Evidence Required:_** Screenshots demonstrating both successful access and deliberate "Permission denied" errors to prove the security barriers work.  

# **_Phase 3: Data Survivability and Restoration_**
  -Establish an automated, scheduled backup routine to a secondary location.  
  -**_Evidence Required:_** Prove the backup works by intentionally deleting data, restoring it, and executing a before-and-after cryptographic hash comparison (e.g., sha256sum) to verify the file is identical. 
  
# **_Phase 4: Usability and Automation_**
  -Develop user-friendly shell scripts to automate daily operational tasks (such as running backups, checking system health, or creating new records) for non-technical staff.  
  -**_Deliverables:_** Working script files and a plain-language instructional README written specifically for everyday employees to follow without technical jargon.  
  
# **_Phase 5: Real-World Deployment Plan_**
-Propose a practical hardware setup with cost estimates, ensuring failsafes like an Uninterruptible Power Supply (UPS) to prevent data corruption during outages.  
-Map out the proposed network topology (e.g., using a Packet Tracer diagram) showing the server, network hardware, and client devices.  
-Design automated system monitoring to alert management of critical issues, such as low disk space.  

# **Final Submission Checklist**
_1. A compiled master document detailing all five phases.  
2. Functional scripts and the non-technical user README.  
3. The exported network diagram.  
4. A dedicated folder containing all terminal logs and screenshot evidence._
