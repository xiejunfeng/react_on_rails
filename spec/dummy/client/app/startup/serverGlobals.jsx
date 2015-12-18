// Shows the mapping from the exported object to the name used by the server rendering.

import ReactOnRails from 'react_on_rails';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

// React components
import HelloWorld from '../components/HelloWorld';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';

// Generator function
import HelloWorldApp from './HelloWorldApp';

// Example of React + Redux
import ReduxApp from './ServerReduxApp';

// Example of React Router with Server Rendering
import ServerRouterApp from './ServerRouterApp';

// We can use the node global object for exposing.
// NodeJs: https://nodejs.org/api/globals.html#globals_global
global.HelloString = HelloString;
global.ReduxApp = ReduxApp;
global.HelloWorld = HelloWorld;
global.HelloWorldWithLogAndThrow = HelloWorldWithLogAndThrow;
global.HelloWorldES5 = HelloWorldES5;
global.HelloWorldApp = HelloWorldApp;
global.RouterApp = ServerRouterApp;

// ReactOnRails.registerComponent('HelloString', HelloString);
// ReactOnRails.registerComponent('ReduxApp', ReduxApp);
// ReactOnRails.registerComponent('HelloWorld', HelloWorld);
// ReactOnRails.registerComponent('HelloWorldWithLogAndThrow', HelloWorldWithLogAndThrow);
// ReactOnRails.registerComponent('HelloWorldES5', HelloWorldES5);
// ReactOnRails.registerComponent('HelloWorldApp', HelloWorldApp);
// ReactOnRails.registerComponent('RouterApp', RouterApp);

// Alternative syntax for exposing Vars
// NOTE: you must set exports.output.libraryTarget = 'this' in your webpack.server.js file.
// See client/webpack.server.js:16
// require("expose?HelloString!../non_react/HelloString");
// require("expose?HelloWorld!../components/HelloWorld");
