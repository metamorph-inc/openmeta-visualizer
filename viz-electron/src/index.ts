import { app, BrowserWindow, Menu, shell, dialog } from 'electron';
declare const MAIN_WINDOW_WEBPACK_ENTRY: any;

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (require('electron-squirrel-startup')) { // eslint-disable-line global-require
  app.quit();
}

const createWindow = () => {
  if(process.argv.length !== 2) {
    dialog.showMessageBoxSync(null, {
      type: "error",
      title: "OpenMETA Visualizer",
      message: "This application must be launched from the OpenMETA Visualizer."
    });

    app.exit(1);
  }

  const url = new URL(process.argv[1]);
  if(url.hostname !== "localhost" && url.hostname !== "127.0.0.1") {
    dialog.showMessageBoxSync(null, {
      type: "error",
      title: "OpenMETA Visualizer",
      message: "This application must be launched from the OpenMETA Visualizer."
    });

    app.exit(1);
  }

  const isMac = process.platform === 'darwin'

  const template: any = [
    // { role: 'appMenu' }
    ...(isMac ? [{
      label: app.name,
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideothers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    }] : []),
    // { role: 'fileMenu' }
    {
      label: 'File',
      submenu: [
        { role: 'close' }
      ]
    },
    // { role: 'editMenu' }
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
        ...(isMac ? [
          { role: 'pasteAndMatchStyle' },
          { role: 'delete' },
          { role: 'selectAll' },
          { type: 'separator' },
          {
            label: 'Speech',
            submenu: [
              { role: 'startspeaking' },
              { role: 'stopspeaking' }
            ]
          }
        ] : [
          { role: 'delete' },
          { type: 'separator' },
          { role: 'selectAll' }
        ])
      ]
    },
    // { role: 'viewMenu' }
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        { role: 'forcereload' },
        { role: 'toggledevtools' },
        { type: 'separator' },
        { role: 'resetzoom' },
        { role: 'zoomin' },
        { role: 'zoomout' },
        { type: 'separator' },
        { role: 'togglefullscreen' }
      ]
    },
    // { role: 'windowMenu' }
    {
      label: 'Window',
      submenu: [
        { role: 'minimize' },
        { role: 'zoom' },
        ...(isMac ? [
          { type: 'separator' },
          { role: 'front' },
          { type: 'separator' },
          { role: 'window' }
        ] : [
          { role: 'close' }
        ])
      ]
    },
    {
      role: 'help',
      submenu: [
        {
          label: 'Visualizer Documentation',
          click: async () => {
            const { shell } = require('electron')
            await shell.openExternal('http://docs.metamorphsoftware.com/doc/reference_execution/visualizer/visualizer.html')
          }
        },
        { type: 'separator' },
        {
          label: 'About OpenMETA',
          click: async () => {
            const { shell } = require('electron')
            await shell.openExternal('https://openmeta.metamorphsoftware.com/')
          }
        },
        {
          label: 'About MetaMorph',
          click: async () => {
            const { shell } = require('electron')
            await shell.openExternal('https://metamorphsoftware.com/')
          }
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template)
  Menu.setApplicationMenu(menu)

  // Create the browser window.
  const mainWindow = new BrowserWindow({
    height: 800,
    width: 1000,
    title: "OpenMETA Visualizer",
    webPreferences: {
      enableRemoteModule: false
    }
  });

  const handleNavigate = async (event: Electron.Event, url: string) => {
    const targetUrl = new URL(url);
    const currentUrl = new URL(mainWindow.webContents.getURL());
    if(targetUrl.hostname === currentUrl.hostname && targetUrl.port === currentUrl.port && targetUrl.protocol === currentUrl.protocol) {
      // Allow default behavior
    } else {
      event.preventDefault();
      await shell.openExternal(url);
    }
  };

  const handleNewWindow = async (sourceWindow: BrowserWindow, event: Electron.NewWindowEvent, url: string, frameName: string, disposition: string, options: Electron.BrowserWindowConstructorOptions) => {
    const targetUrl = new URL(url);
    const currentUrl = new URL(mainWindow.webContents.getURL());
    if(targetUrl.hostname === currentUrl.hostname && targetUrl.port === currentUrl.port && targetUrl.protocol === currentUrl.protocol) {
      event.preventDefault();
      const win = new BrowserWindow({
        title: "OpenMETA Visualizer",
        webPreferences: {
          enableRemoteModule: false,
          openerId: sourceWindow.id // openerId (which we need to get Electron to permit postMessage to children) is missing from the Typescript defs for webPreferences...
        } as any,
      });
      //win.once('ready-to-show', () => win.show());
      win.webContents.on("new-window", handleNewWindow.bind(undefined, win));
      win.webContents.on("will-navigate", handleNavigate);
      win.loadURL(url);
      event.newGuest = win;
    } else {
      event.preventDefault();
      await shell.openExternal(url);
    }
  };

  mainWindow.webContents.on("new-window", handleNewWindow.bind(undefined, mainWindow));
  mainWindow.webContents.on("will-navigate", handleNavigate);

  // and load the index.html of the app.
  //mainWindow.loadURL(MAIN_WINDOW_WEBPACK_ENTRY);
  mainWindow.loadURL(process.argv[1])

  // Open the DevTools.
  //mainWindow.webContents.openDevTools();
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow);

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and import them here.
