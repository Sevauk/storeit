SystemJS.config({
  paths: {
    "github:": "build/jspm_packages/github/",
    "npm:": "build/jspm_packages/npm/"
  },
  browserConfig: {
    "baseURL": "/",
    "paths": {
      "storeit-desktop-gui/": "build/app/"
    }
  },
  nodeConfig: {
    "paths": {
      "storeit-desktop-gui/": "src/"
    }
  },
  packages: {
    "storeit-desktop-gui": {
      "main": "build/app/index.js"
    }
  }
});

SystemJS.config({
  packageConfigPaths: [
    "github:*/*.json",
    "npm:@*/*.json",
    "npm:*.json"
  ],
  map: {
    "assert": "github:jspm/nodelibs-assert@0.2.0-alpha",
    "buffer": "github:jspm/nodelibs-buffer@0.2.0-alpha",
    "child_process": "github:jspm/nodelibs-child_process@0.2.0-alpha",
    "coffee": "github:forresto/system-coffee@0.1.2",
    "css": "github:systemjs/plugin-css@0.1.23",
    "events": "github:jspm/nodelibs-events@0.2.0-alpha",
    "fs": "github:jspm/nodelibs-fs@0.2.0-alpha",
    "http": "github:jspm/nodelibs-http@0.2.0-alpha",
    "https": "github:jspm/nodelibs-https@0.2.0-alpha",
    "jade": "github:johnsoftek/plugin-jade@1.1.2",
    "module": "github:jspm/nodelibs-module@0.2.0-alpha",
    "os": "github:jspm/nodelibs-os@0.2.0-alpha",
    "path": "github:jspm/nodelibs-path@0.2.0-alpha",
    "process": "github:jspm/nodelibs-process@0.2.0-alpha",
    "stream": "github:jspm/nodelibs-stream@0.2.0-alpha",
    "tty": "github:jspm/nodelibs-tty@0.2.0-alpha",
    "url": "github:jspm/nodelibs-url@0.2.0-alpha",
    "util": "github:jspm/nodelibs-util@0.2.0-alpha",
    "vm": "github:jspm/nodelibs-vm@0.2.0-alpha"
  },
  packages: {
    "github:johnsoftek/plugin-jade@1.1.2": {
      "map": {
        "jade-compiler": "npm:jade@1.11.0"
      }
    },
    "npm:jade@1.11.0": {
      "map": {
        "jstransformer": "npm:jstransformer@0.0.2",
        "character-parser": "npm:character-parser@1.2.1",
        "constantinople": "npm:constantinople@3.0.2",
        "void-elements": "npm:void-elements@2.0.1",
        "mkdirp": "npm:mkdirp@0.5.1",
        "with": "npm:with@4.0.3",
        "transformers": "npm:transformers@2.1.0",
        "commander": "npm:commander@2.6.0",
        "uglify-js": "npm:uglify-js@2.7.0",
        "clean-css": "npm:clean-css@3.4.18"
      }
    },
    "npm:constantinople@3.0.2": {
      "map": {
        "acorn": "npm:acorn@2.7.0"
      }
    },
    "npm:with@4.0.3": {
      "map": {
        "acorn": "npm:acorn@1.2.2",
        "acorn-globals": "npm:acorn-globals@1.0.9"
      }
    },
    "npm:clean-css@3.4.18": {
      "map": {
        "commander": "npm:commander@2.8.1",
        "source-map": "npm:source-map@0.4.4"
      }
    },
    "npm:transformers@2.1.0": {
      "map": {
        "uglify-js": "npm:uglify-js@2.2.5",
        "promise": "npm:promise@2.0.0",
        "css": "npm:css@1.0.8"
      }
    },
    "npm:uglify-js@2.7.0": {
      "map": {
        "uglify-to-browserify": "npm:uglify-to-browserify@1.0.2",
        "async": "npm:async@0.2.10",
        "source-map": "npm:source-map@0.5.6",
        "yargs": "npm:yargs@3.10.0"
      }
    },
    "npm:jstransformer@0.0.2": {
      "map": {
        "is-promise": "npm:is-promise@2.1.0",
        "promise": "npm:promise@6.1.0"
      }
    },
    "npm:mkdirp@0.5.1": {
      "map": {
        "minimist": "npm:minimist@0.0.8"
      }
    },
    "npm:acorn-globals@1.0.9": {
      "map": {
        "acorn": "npm:acorn@2.7.0"
      }
    },
    "github:jspm/nodelibs-url@0.2.0-alpha": {
      "map": {
        "url-browserify": "npm:url@0.11.0"
      }
    },
    "github:jspm/nodelibs-stream@0.2.0-alpha": {
      "map": {
        "stream-browserify": "npm:stream-browserify@2.0.1"
      }
    },
    "npm:commander@2.8.1": {
      "map": {
        "graceful-readlink": "npm:graceful-readlink@1.0.1"
      }
    },
    "github:jspm/nodelibs-os@0.2.0-alpha": {
      "map": {
        "os-browserify": "npm:os-browserify@0.2.1"
      }
    },
    "npm:uglify-js@2.2.5": {
      "map": {
        "source-map": "npm:source-map@0.1.43",
        "optimist": "npm:optimist@0.3.7"
      }
    },
    "npm:promise@2.0.0": {
      "map": {
        "is-promise": "npm:is-promise@1.0.1"
      }
    },
    "github:jspm/nodelibs-http@0.2.0-alpha": {
      "map": {
        "http-browserify": "npm:stream-http@2.3.0"
      }
    },
    "npm:promise@6.1.0": {
      "map": {
        "asap": "npm:asap@1.0.0"
      }
    },
    "github:jspm/nodelibs-buffer@0.2.0-alpha": {
      "map": {
        "buffer-browserify": "npm:buffer@4.7.1"
      }
    },
    "npm:css@1.0.8": {
      "map": {
        "css-stringify": "npm:css-stringify@1.0.5",
        "css-parse": "npm:css-parse@1.0.4"
      }
    },
    "npm:stream-browserify@2.0.1": {
      "map": {
        "inherits": "npm:inherits@2.0.1",
        "readable-stream": "npm:readable-stream@2.1.4"
      }
    },
    "npm:url@0.11.0": {
      "map": {
        "querystring": "npm:querystring@0.2.0",
        "punycode": "npm:punycode@1.3.2"
      }
    },
    "npm:source-map@0.4.4": {
      "map": {
        "amdefine": "npm:amdefine@1.0.0"
      }
    },
    "npm:source-map@0.1.43": {
      "map": {
        "amdefine": "npm:amdefine@1.0.0"
      }
    },
    "npm:stream-http@2.3.0": {
      "map": {
        "inherits": "npm:inherits@2.0.1",
        "xtend": "npm:xtend@4.0.1",
        "readable-stream": "npm:readable-stream@2.1.4",
        "to-arraybuffer": "npm:to-arraybuffer@1.0.1",
        "builtin-status-codes": "npm:builtin-status-codes@2.0.0"
      }
    },
    "npm:yargs@3.10.0": {
      "map": {
        "cliui": "npm:cliui@2.1.0",
        "window-size": "npm:window-size@0.1.0",
        "camelcase": "npm:camelcase@1.2.1",
        "decamelize": "npm:decamelize@1.2.0"
      }
    },
    "npm:buffer@4.7.1": {
      "map": {
        "ieee754": "npm:ieee754@1.1.6",
        "isarray": "npm:isarray@1.0.0",
        "base64-js": "npm:base64-js@1.1.2"
      }
    },
    "npm:optimist@0.3.7": {
      "map": {
        "wordwrap": "npm:wordwrap@0.0.3"
      }
    },
    "npm:cliui@2.1.0": {
      "map": {
        "wordwrap": "npm:wordwrap@0.0.2",
        "center-align": "npm:center-align@0.1.3",
        "right-align": "npm:right-align@0.1.3"
      }
    },
    "npm:readable-stream@2.1.4": {
      "map": {
        "inherits": "npm:inherits@2.0.1",
        "isarray": "npm:isarray@1.0.0",
        "buffer-shims": "npm:buffer-shims@1.0.0",
        "process-nextick-args": "npm:process-nextick-args@1.0.7",
        "string_decoder": "npm:string_decoder@0.10.31",
        "core-util-is": "npm:core-util-is@1.0.2",
        "util-deprecate": "npm:util-deprecate@1.0.2"
      }
    },
    "npm:center-align@0.1.3": {
      "map": {
        "align-text": "npm:align-text@0.1.4",
        "lazy-cache": "npm:lazy-cache@1.0.4"
      }
    },
    "npm:right-align@0.1.3": {
      "map": {
        "align-text": "npm:align-text@0.1.4"
      }
    },
    "npm:align-text@0.1.4": {
      "map": {
        "kind-of": "npm:kind-of@3.0.3",
        "longest": "npm:longest@1.0.1",
        "repeat-string": "npm:repeat-string@1.5.4"
      }
    },
    "npm:kind-of@3.0.3": {
      "map": {
        "is-buffer": "npm:is-buffer@1.1.3"
      }
    }
  }
});
