/*
This is a two-ways hash map. For example:

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

import {logger} from './common/log.js'

export class TwoHashMap {

  constructor() {
    this.map1 = {}
    this.map2 = {}
  }

  subAdd(map, value1, value2) {
    if (map[value1] === undefined) {
      map[value1] = new Set()
    }
    map[value1].add(value2)
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
    return value1 in map ? map[value1].has(value2) : false
  }

  test(value1, value2) {
    if (this.subTest(this.map1, value1, value2)) return true
    if (this.subTest(this.map2, value1, value2)) return true
    return false
  }

  wipe(mapA, mapB, value) {
    if (value in mapA) {
      for (const item of mapA[value]) {
        mapB[item].delete(value)
        if (mapB[item].size === 0)
          delete mapB[item]
      }
      delete mapA[value]
    }
  }

  countSub(map, value) {
    return value in map ? map[value].size : 0
  }

  count(value) {
    const count = this.countSub(this.map1, value)
    if (count !== 0)
      return count
    return this.countSub(this.map2, value)
  }

  remove(value) {
    this.wipe(this.map1, this.map2, value)
    this.wipe(this.map2, this.map1, value)
  }

  selectA(dontHave, howMany) {

    const selected = new Set()

    for (const item of Object.keys(this.map1)) {
      if (this.map2[dontHave] && this.map2[dontHave].has(item))
        continue
      selected.add(item)
      if (--howMany <= 0)
        break
    }
    return selected
  }
}
