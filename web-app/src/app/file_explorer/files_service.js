let files = [
  {
    'path': 'storeit',
    'unique_hash': 'qd4q5sds',
    'kind': 'dir',
    'files': [
      {
        'path': 'storeit/bar',
        'unique_hash': 'aze56sqd',
        'kind': 'file'
      },
      {
        'path': 'storeit/folder',
        'unique_hash': 'aze56sqd',
        'kind': 'dir',
        'files': [
          {
            'path': 'storeit/folder/file1',
            'unique_hash': 'aze56sqd',
            'kind': 'file',
          },
          {
            'path': 'storeit/folder/file2',
            'unique_hash': 'aze56sqd',
            'kind': 'file',
          }
        ]
      },
      {
        'path': 'storeit/folder2',
        'unique_hash': 'aze56sqd',
        'kind': 'dir',
        'files': [
        ]
      },
    ]
  },
  {
    'path': 'foo',
    'unique_hash': '46489qsd',
    'kind': 'file'
  }
]

// if (window.userFiles) files = window.userFiles
//
export default class FilesService {
  constructor() {
    'ngInject'
  }

  getFiles() {
    return window.join().then((res) => res.home)
  }
}
