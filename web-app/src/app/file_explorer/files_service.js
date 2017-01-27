export default class FilesService {
  constructor(StoreItClient) {
    'ngInject'

    this.client = StoreItClient
  }

  getFiles() {
    return this.client.request('JOIN', JSON.parse(localStorage.getItem('authParams')))
      .then((res) => res.home)
  }
}
