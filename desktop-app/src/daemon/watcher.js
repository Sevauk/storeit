import chokidar from 'chokidar'

import logger from '../../lib/log'
import userFile from './user-file'

export class FsEvent {
  constructor(type, p, stats={}) {
    this.path = userFile.storePath(p)
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
  /Thumbs.db$/,
]

export default class Watcher {
  constructor(watchPath, ignoredPath, notifier) {
    this.ignoreSet = new Set()
    this.watchPath = watchPath
    this.ignoredPath = Array.isArray(ignoredPath) ? ignoredPath : [ignoredPath]
    this.notifier = notifier
  }

  start() {
    this.monitor = chokidar.watch(this.watchPath, {
      persistent: true,
      ignored: [...OS_GENERATED, ...(this.ignoredPath.map(p =>
        p instanceof RegExp ? p : new RegExp(p.replace(/\./g, '\\.'))
      ))]
    })

    this.monitor.on('error', error => logger.error(`[WATCH] Error: ${error}`))

    return new Promise((resolve) => {
      this.monitor.on('ready', () => {
        this.monitor
          .on('add', (p, stats) => this.dispatch('add', p, stats))
          .on('addDir', (p, stats) => this.dispatch('addDir', p, stats))
          .on('change', (p, stats) => this.dispatch('change', p, stats))
          .on('unlink', p => this.dispatch('unlink', p))
          .on('unlinkDir', p => this.dispatch('unlinkDir', p))
        logger.info('[WATCH] Initial scan complete. Ready for changes')
        resolve()
      })
    })
  }

  stop() {
    if (this.monitor) this.monitor.close()
  }

  dispatch(evType, p, stats) {
    let ev = new FsEvent(evType, p, stats)

    if (!this.ignoreEvent(ev)) {
      if (!this.notifier(ev)) {
        logger.error(`[WATCH] unhandled event ${ev}`)
      }
    }
    else {
      logger.debug(`[WATCH] ignored event: ${logger.toJson(ev)}`)
    }
  }

  ignoreEvent(ev) {
    if (ev.type === 'FDEL')
      return false // @Sevauk: ?

    return this.isIgnored(ev.path)
  }

  ignore(file) {
    this.ignoreSet.add(file)
    Promise.delay(20000000).then(() => this.unignore(file))
  }

  unignore(file) {
    this.ignoreSet.delete(file)
  }

  isIgnored(file) {
    return this.ignoreSet.has(file)
  }
}
