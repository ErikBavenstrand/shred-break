const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

const SITE = 'https://shredsauce.com';
let panel;
let fullPage = false;

function setFullPage(value) {
  fullPage = value;
  vscode.commands.executeCommand('setContext', 'shredsauce.fullPage', value);
  panel?.webview.postMessage({ type: 'setFullPage', value });
}

function play(context) {
  if (panel) { panel.reveal(); return; }
  const media = vscode.Uri.joinPath(context.extensionUri, 'media');
  panel = vscode.window.createWebviewPanel('shredsauce', 'Shredsauce', vscode.ViewColumn.Active, {
    enableScripts: true,
    retainContextWhenHidden: true, // keep the run going when you switch tabs
    localResourceRoots: [media],
  });
  panel.iconPath = {
    light: vscode.Uri.joinPath(media, 'tab-light.svg'),
    dark: vscode.Uri.joinPath(media, 'tab-dark.svg'),
  };
  panel.onDidDispose(() => {
    panel = undefined;
    setFullPage(false);
    vscode.commands.executeCommand('setContext', 'shredsauce.open', false);
  }, null, context.subscriptions);
  vscode.commands.executeCommand('setContext', 'shredsauce.open', true);

  const html = fs.readFileSync(path.join(context.extensionPath, 'game.html'), 'utf8');
  panel.webview.html = html
    .replaceAll('{{cspSource}}', panel.webview.cspSource)
    .replaceAll('{{icon}}', panel.webview.asWebviewUri(vscode.Uri.joinPath(media, 'icon.png')).toString());
  setFullPage(false);
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('shredsauce.play', () => play(context)),
    vscode.commands.registerCommand('shredsauce.reload', () => panel?.webview.postMessage({ type: 'reload' })),
    vscode.commands.registerCommand('shredsauce.showFullPage', () => setFullPage(true)),
    vscode.commands.registerCommand('shredsauce.showGameOnly', () => setFullPage(false)),
    vscode.commands.registerCommand('shredsauce.openInBrowser', () => vscode.env.openExternal(vscode.Uri.parse(SITE))),
  );

  const item = vscode.window.createStatusBarItem('shredsauce.play', vscode.StatusBarAlignment.Right, 100);
  item.name = 'Shredsauce';
  item.text = '🏂 Shred';
  item.tooltip = new vscode.MarkdownString('**Shredsauce**  \nClick to drop in');
  item.command = 'shredsauce.play';
  item.show();
  context.subscriptions.push(item);
}

module.exports = { activate, deactivate() {} };
