# AlienGooseInvasion-RokuChannel
A Roku channel dedicated to the eminent threat of invasion by geese from outer space!!!

Contents
* server -- folder for Node.js files and media files 
  * server.js -- main server javascript code
  * package.json -- the package file used to tell npm about the projects dependencies
  * public -- folder to hold all files accessible to the public on the server.  also the site root
    * ads -- holds ads for all channels
    * local -- holds ads to be served locally only
      * ### -- folder for each metro_code area (ex. 751 for denver/CO area)
    * aliengooseinvasion -- holds files specific to the channel
* channel
  * manifest -- file that describes the channel to ROKU
  * source -- holds the brighscript files that define the channel
    * main.brs -- the main entry point for the channel's code
  * images -- holds the images used to build the user interface
  * fonts -- holds custom fonts
  
  
