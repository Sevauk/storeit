/* This is a two-ways hash map. For example:

map1:

  {
    'adrien.morel@me.com': {'hash1', 'hash2', 'hash3'}
    'james.bond@hotmail.com': {'hash2', 'hash4'}
  }

map2:

  {
    'hash1': {'adrien.morel@me.com'},
    'hash2': {'adrien.morel@me.com', 'james.bond@hotmail.com'},
    'hash3': {'adrien.morel@me.com'},
    'hash4': {'james.bond@hotmail.com'}
  }
*/

export class TwoHashMap {

  constructor() {
    this.map1 = {}
    this.map2 = {}
  }

  subAdd(map, value1, value2) {
    if (map[value1] === undefined) {
      map[value1] = {}
    }
    map[value1][value2] = null
  }

  add(value1, value2) {
    this.subAdd(this.map1, value1, value2)
    this.subAdd(this.map2, value2, value1)
  }

  get(value) {
    if (value in this.map1) {
      return this.map1[value]
    }
    else {
      return this.map2[value]
    }
  }

  subTest(map, value1, value2) {
    if (value1 in map) {
      return value2 in map[value1]
    }
    return false
  }

  test(value1, value2) {
    if (this.subTest(this.map1, value1, value2)) return true
    if (this.subTest(this.map2, value1, value2)) return true
    return false
  }

  wipe(mapA, mapB, value) {
    if (value in mapA) {
      for (const item of Object.keys(mapA[value])) {
        delete mapB[item][value]
        if (Object.keys(mapB[item]).length === 0)
          delete mapB[item]
      }
      delete mapA[value]
    }
  }

  remove(value) {
    this.wipe(this.map1, this.map2, value)
    this.wipe(this.map2, this.map1, value)
  }
}
