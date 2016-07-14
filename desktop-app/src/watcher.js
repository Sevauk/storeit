import chokidar from 'chokidar'
import {logger} from '../lib/log'

const STORE_NAME = '.storeit'

export class EventType {
  constructor(type, path, stats={}) {
    this.path = path
    this.stats = stats
    switch (type) {
    case 'add':
      Object.assign(this, {
        fileKind: 'file',
        type: 'add'
      })
      break
    case 'addDir':
      Object.assign(this, {
        fileKind: 'directory',
        type: 'add'
      })
      break
    case 'unlink':
      Object.assign(this, {
        fileKind: 'file',
        type: 'remove'
      })
      break
    case 'unlinkDir':
      Object.assign(this, {
        fileKind: 'directory',
        type: 'remove'
      })
      break
    case 'change':
      Object.assign({
        fileKind: 'file',
        type: 'update'
      })
      break
    default:
      throw {msg: 'Unexpected error occured'}
    }
  }
}

class Watcher {
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
        .on('unlink', (path, stats) => this.listener('unlink', stats))
        .on('addDir', (path, stats) => this.listener('addDir', stats))
        .on('unlinkDir', (path, stats) => this.listener('unlinkDir', stats))
    })
  }

  listener(evType, path, stats) {
    let ev = new EventType(evType, path, stats)
    logger.log(`[FileWatcher] ${ev.type.toUpperCase()} ${ev.fileKind} ${path}`)

    if (!this.ignoreEvent(ev)) {
      let handler = this.handlers[ev.type]
      if (handler) return handler(ev)
      else logger.warn(`[FileWatcher] unhandled event ${ev}`)
    }
    return null
  }

  ignoreEvent(ev) {
    return false
  }

  setListener(eventType, listener) {
    this.handlers[eventType] = listener
  }

  pushIgnoreEvent(ev) {
    this.ignoredEvents.push(ev)
  }
}
