#
# MIT License
#
# Copyright (c) 2019 Alexis Munsayac
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#
# author Alexis Munsayac <alexis.munsayac@gmail.com>
# copyright Alexis Munsayac 2019
#
require "./Single"
require "./Completable"
require "./Maybe"
require "./SingleObserver"
require "./SingleSource"
require "./SingleEmitter"
require "./Subscription"
require "./Scheduler"
require "./observers/single/*"

abstract class Single(T)
  include SingleSource(T)

  def self.amb(sources : Array(SingleSource(T))) : Single(T)
    return SingleAmbArray(T).new(sources)
  end

  def self.amb(sources : Enumerable(SingleSource(T))) : Single(T)
    return SingleAmbEnumerable(T).new(sources)
  end

  def self.amb(sources : Indexable(SingleSource(T))) : Single(T)
    return SingleAmbIndexable(T).new(sources)
  end

  def self.create(onSubscribe : Proc(SingleEmitter(T), Nil)) : Single(T)
    return SingleCreate(T).new(onSubscribe)
  end

  def self.just(value : T) : Single(T)
    return SingleJust(T).new(value)
  end

  def self.never : Single(Nil)
    return SingleNever.instance
  end

  def self.timer(delay : Float64, scheduler : Scheduler) : Single(Int64)
    return SingleTimer.new(delay, scheduler)
  end

  def self.wrap(source : SingleSource(T)) : Single(T)
    if (source.is_a?(Single(T)))
      return source
    end
    return SingleFromSource(T).new(source)
  end

  def compose(transformer : Proc(Single(T), SingleSource(R))) : Single(R) forall R
    return wrap(transformer.call(self))
  end

  def filter(filter : Proc(T, Bool)) : Maybe(T)
    return SingleFilter(T).new(self, filter)
  end

  def ignoreElement : Completable
    return SingleIgnoreElement(T).new(self)
  end

  def lift(operator : Proc(SingleObserver(R), SingleObserver(T))) : Single(R) forall R
    return SingleLift(T, R).new(self, operator)
  end

  def map(mapper : Proc(T, R)) : Single(R) forall R
    return SingleMap(T, R).new(self, mapper)
  end

  def subscribeWith(observer : SingleObserver(T)) : SingleObserver(T)
    subscribeActual(observer)
    return observer
  end

  def subscribe(observer : SingleObserver(T))
    subscribeActual(observer)
  end

  def subscribe(onSuccess : Proc(T, Nil)) : Subscription
    return subscribeWith(OnSuccessSingleObserver(T).new(onSuccess))
  end

  def subscribe(onEvent : Proc(T, Exception, Nil)) : Subscription
    return subscribeWith(BiconsumerSingleObserver(T).new(onEvent))
  end

  def subscribe(onSuccess : Proc(T, Nil), onError : Proc(Exception, Nil)) : Subscription
    return subscribeWith(LambdaSingleObserver(T).new(onSuccess, onError))
  end

  abstract def subscribeActual(observer : SingleObserver(R)) forall R
end
