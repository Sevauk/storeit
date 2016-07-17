import chokidar from 'chokidar'
import {logger} from '../lib/log'

const STORE_NAME = '.storeit'

export class EventType {
  constructor(type, path, stats={}) {
    this.path = path
    this.meta = stats
    switch (type) {
    case 'add':
      Object.assign(this, {
        isDir: false,
        type: 'FADD'
      })
      break
    case 'addDir':
      Object.assign(this, {
        isDir: true,
        type: 'FADD'
      })
      break
    case 'unlink':
      Object.assign(this, {
        isDir: false,
        type: 'FDEL'
      })
      break
    case 'unlinkDir':
      Object.assign(this, {
        isDir: true,
        type: 'FDEL'
      })
      break
    case 'change':
      Object.assign(this, {
        isDir: false,
        type: 'FUPT'
      })
      break
    default:
      logger.error('error here')
      throw {msg: 'Unexpected error occured'}
    }
  }
}

export default class Watcher {
  constructor(dirPath) {
    this.handlers = {}
    this.ignoredEvents = []
    this.watcher = chokidar.watch(dirPath, {
      persistent: true,
      ignored: `.${STORE_NAME}`
    })

    this.watcher.on('error', error =>
      logger.error(`[FileWatcher] Error: ${error}`))

    this.watcher.on('ready', () => {
      logger.info('[FileWatcher]Initial scan complete. Ready for changes')
      this.watcher
        .on('add', (path, stats) => this.listener('add', path, stats))
        .on('change', (path, stats) => this.listener('change', path, stats))
        .on('unlink', (path, stats) => this.listener('unlink', path, stats))
        .on('addDir', (path, stats) => this.listener('addDir', path, stats))
        .on('unlinkDir', (path, stats) =>
          this.listener('unlinkDir', path, stats))
    })
  }

  listener(evType, path, stats) {
    let ev = new EventType(evType, path, stats)
    logger.log(`[FileWatcher] ${ev.type.toUpperCase()} ${ev.fileKind} ${path}`)

    if (!this.ignoreEvent(ev)) {
      return this.handler(ev)
    }
    return null
  }

  ignoreEvent(ev) {
    return false
  }

  setEventHandler(listener) {
    this.handler = listener
  }

  pushIgnoreEvent(ev) {
    this.ignoredEvents.push(ev)
  }
}
