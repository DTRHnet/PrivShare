 ``` 
      ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::       
      ::                                                                                  ::       
      ::      _____     ______   ______     __  __     __   __     ______     ______      ::       
      ::     /\  __-.  /\__  _\ /\  == \   /\ \_\ \   /\ "-.\ \   /\  ___\   /\__  _\     ::       
      ::     \ \ \/\ \ \/_/\ \/ \ \  __<   \ \  __ \  \ \ \-.  \  \ \  __\   \/_/\ \/     ::       
      ::      \ \____-    \ \_\  \ \_\ \_\  \ \_\ \_\  \ \_\\"\_\  \ \_____\    \ \_\     ::       
      ::       \/____/     \/_/   \/_/ /_/   \/_/\/_/   \/_/ \/_/   \/_____/     \/_/     ::       
      ::                                                                                  ::       
      :::::::::::::::::::::::::::::::: [ HTTPS://DTRH.NET ] ::::::::::::::::::::::::::::::::       

           :: PROJECT: . . . . . . . . . . . . . . . . . . . . . . . . . . PrivShare               
           :: VERSION: . . . . . . . . . . . . . . . . . . . . . . . . . . 0.4.0                   
           :: AUTHOR:  . . . . . . . . . . . . . . . . . . . . . . . . . . KBS                     
           :: CREATED: . . . . . . . . . . . . . . . . . . . . . . . . . . 2025-02-17              
           :: LAST MODIFIED: . . . . . . . . . . . . . . . . . . . . . . . 2025-03-03              
                                                                                             
              README - PrivShare (v0.4.0)                              admin@dtrh.net
 
⚙ **Overview**  
PrivShare is a locally hosted, secure file sharing and messaging solution designed to prioritize privacy and
encryption. It provides a  robust system for users to  securely upload and share files, engage  in encrypted
discussions, and manage self-destructive  notes and PGP-encrypted content. With a focus on local storage and
data  security, it  allows  users to  interact  within a web front-end  whileensuring secure  access through
various authentication methods and user roles. The ultimate  goal is to  help simplify and automate  locally
hosted  instances of  PrivShare - effectively  bypassing any reliance  on external services  (cloud storage,
pastebin, privnote). PrivShare  lets you take control of your  privacy, and avoid big player cloud  services
in  favor of  your own quiet and  secure instance while retaining  all of the tools and functionality  to be
expected in a file hosting service.

📂 ## **Key Features**  
- **Secure  File  Sharing**: Share  files  between  users  locally, without  relying  on cloud architecture,
    ensuring full control over your data.  
- **Encrypted Communication**: All messages and  discussions between users are fully encrypted  to maintain
    confidentiality.  
- **Self-Destructive Notes**: Create and share temporary notes that automatically self-destruct after being
    viewed, preserving privacy.  
- **PGP File Encryption**: Upload and share files that are PGP encrypted for secure, private exchanges.  
- **Role-Based Access Control**: Implement user roles  with different access  levels (e.g., Admin, User) to
    manage permissions and maintain security.  
- **Configurable Menus**: Customize  the user interface  with a  structured `menu.yaml`, which  defines the
    sidebar, footer, and mobile menus—complete with icons for ease of navigation.  
- **Automatic Compression & Thumbnails**: Support for video files to generate thumbnails and  compress them
    automatically, ensuring quick and efficient file management.  
- **Secure Deletion**: Only users with appropriate roles (Admins or Owners) can delete files, ensuring role
    compliance and minimizing accidental loss of data.
 
 🚀 **Usage**  
 1. Install and configure Python environment.  
 2. Adjust your `menu.yaml` and relevant config files to match desired menu structure.  
 3. Run migrations for any database changes.  
 4. Launch the Flask app (directly or via WSGI).  
 5. Use the side menu or mobile menu to upload, preview, and manage files.  
 
 🔧 **Customization**  
 - **Menus**: Edit `menu.yaml` for new sections or icons.  
 - **Extensions**: Expand or adjust recognized file categories in the config.  
 - **Testing**: Mock out `subprocess.run` calls if testing thumbnail/compression logic.  
 
 🔒 **Security**  
 - Validate file extensions.  
 - Confirm correct roles are assigned for uploads or deletions.  
 - Keep FFMPEG or other tools updated.  
 
 💡 **Why PrivShare?**  
 - Easy to maintain with robust test coverage.  
 - Organized menus guide users to specific file categories.  
 - Minimal friction for everyday file management tasks.  
 
 🌐 **Deployment**  
 - Use a WSGI server (e.g., Gunicorn, Passenger) for production.  
 - Ensure config references the correct module path if patching methods in tests.  
