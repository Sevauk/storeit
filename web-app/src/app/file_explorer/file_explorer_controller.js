export default class FileExplorerController {
  constructor(FilesService, $scope) {
    'ngInject'

    this.scope = $scope
    FilesService.getFiles()
      .then((home) => {
        console.log('before:', home)
        this.path = []
        this.root = {home}
        this.cwd = {files: home}
        if (!Array.isArray(this.cwd.files.files)) {
          this.cwd.files = Object
            .keys(this.cwd.files.files)
            .map((key) => this.cwd.files.files[key])
        }
        console.log('after:', this.cwd.files)
        this.scope.$apply()
      })
  }

  action(index) {
    let target = this.cwd.files[index]
    if (target.isDir) {
      this.cd(target)
    }
  }

  cd(dest) {
    this.path.push(this.cwd)
    this.cwd = dest
    if (!Array.isArray(this.cwd.files)) {
      this.cwd.files = Object
        .keys(this.cwd.files)
        .map((key) => this.cwd.files[key])
    }
    console.log('path', this.path)
  }

  parent() {
    let prev = this.path.pop()
    this.cwd = prev
  }
}
