export default class FileExplorerController {
  constructor(FilesService, StoreItClient, $scope) {
    'ngInject'

    this.scope = $scope
    StoreItClient.handlers['FADD'] = (params) => this.recvFADD(params.files[0])
    StoreItClient.handlers['FDEL'] = (params) => this.recvFDEL(params.files[0])
    FilesService.getFiles()
      .then((home) => {
        console.log('before:', home)
        this.path = []
        this.root = home
        this.cwd = home
        console.log('after:', this.cwd.files)
        this.scope.$apply()
      })
  }

  action(fileName) {
    let target = this.cwd.files[fileName]
    if (target.isDir) {
      this.cd(target)
    }
    else {
      const link = document.createElement('a')
      link.download = target.IPFSHash
      link.href = `http://ipfs.io/ipfs/${target.IPFSHash}`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    }
  }

  cd(dest) {
    this.path.push(this.cwd)
    this.cwd = dest
  }

  recvFADD(file) {
    const subDirs = file.path.split('/')
      .filter(dir => dir !== '')
    let curr = this.root
    let i
    for (i = 0; curr.isDir && i < subDirs.length - 1; ++i) {
      curr = curr.files[subDirs[i]]
    }
    curr.files[subDirs[i]] = file
    this.scope.$apply()
  }

  recvFDEL(file) {
    const subDirs = file.split('/')
      .filter(dir => dir !== '')
    let curr = this.root
    let i
    for (i = 0; curr.isDir && i < subDirs.length - 1; ++i) {
      curr = curr.files[subDirs[i]]
    }
    delete curr.files[subDirs[i]]
    this.scope.$apply()
  }

  parent() {
    let prev = this.path.pop()
    this.cwd = prev
  }
}
