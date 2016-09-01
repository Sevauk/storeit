import chokidar from 'chokidar'

import logger from '../../lib/log'
import userFile from './user-file'

export class EventType {
  constructor(type, path, stats={}) {
    this.path = userFile.storePath(path)
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
        throw new Error('[WATCH] EventType: Unexpected error occured')
    }
  }
}

const OS_GENERATED = [
  /.DS_Store$/,
  /.DS_Store?$/,
  /.Spotlight-V100$/,
  /.Trashes$/,
  /ehthumbs.db$/,
  /Thumbs.d$/,
]

export default class Watcher {
  constructor(dirPath) {
    this.handlers = {}
    this.ignoreSet = new Set()

    this.watcher = chokidar.watch(dirPath, {
      persistent: true,
      ignored: [...OS_GENERATED]
    })

    this.watcher.on('error', error => logger.error(`[WATCH] Error: ${error}`))

    this.watcher.on('ready', () => {
      logger.info('[WATCH] Initial scan complete. Ready for changes')
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

    if (!this.ignoreEvent(ev) && this.handler != null) {
      logger.debug(`[WATCH] emitting ${logger.toJson(ev)}`)
      if (!this.handler(ev)) {
        logger.error(`[WATCH] unhandled event ${ev}`)
      }
    }
  }

  ignoreEvent(ev) {
    if (ev.type === 'FDEL')
      return false // @Sevauk: ?

    return this.isIgnored(ev.path)
  }

  setEventHandler(listener) {
    this.handler = listener
  }

  ignore(file) {
    this.ignoreSet.add(file)
    Promise.delay(20000000).then(() => this.unignore(file))
  }

  unignore(file) {
    this.ignoreSet.delete(file)
  }

  isIgnored(file) {
    this.ignoreSet.has(file)
  }
}
