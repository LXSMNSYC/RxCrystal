#
# @license
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
require "./MaybeObserver"
require "./MaybeSource"
require "./MaybeEmitter"
require "./Subscription"
require "./observers/maybe/*"

abstract class Maybe(T)
  include MaybeSource(T)

  def self.amb(sources : Array(MaybeSource(T))) : Maybe(T)
    return MaybeAmbArray(T).new(sources)
  end

  def self.amb(sources : Enumerable(MaybeSource(T))) : Maybe(T)
    return MaybeAmbEnumerable(T).new(sources)
  end

  def self.amb(sources : Indexable(MaybeSource(T))) : Maybe(T)
    return MaybeAmbIndexable(T).new(sources)
  end

  def self.complete : Maybe(Nil)
    return MaybeComplete.instance
  end

  def self.create(onSubscribe : Proc(MaybeEmitter(T), Nil)) : Maybe(T)
    return MaybeCreate.new(onSubscribe)
  end

  def self.just(value : T) : Maybe(T)
    return MaybeJust(T).new(value)
  end

  def self.never : Maybe(Nil)
    return MaybeNever.instance
  end

  def self.wrap(source : MaybeSource(T)) : Maybe(T)
    if (source.is_a?(Maybe(T)))
      return source
    end
    return MaybeFromSource(T).new(source)
  end

  def compose(transformer : Proc(Maybe(T), MaybeSource(R))) : Maybe(R) forall R
    return wrap(transformer.call(self))
  end

  def lift(operator : Proc(MaybeObserver(R), MaybeObserver(T))) : Maybe(R) forall R
    return MaybeLift(T, R).new(self, operator)
  end

  def map(mapper : Proc(T, R)) : Maybe(R) forall R
    return MaybeMap(T, R).new(self, mapper)
  end

  def subscribeWith(observer : MaybeObserver(T)) : MaybeObserver(T)
    subscribeActual(observer)
    return observer
  end

  def subscribe(observer : MaybeObserver(T))
    subscribeActual(observer)
  end

  def subscribe(onSuccess : Proc(T, Nil)) : Subscription
    return subscribeWith(OnSuccessMaybeObserver(T).new(onSuccess))
  end

  def subscribe(onSuccess : Proc(T, Nil), onError : Proc(Exception, Nil)) : Subscription
    return subscribeWith(SuccessErrorMaybeObserver(T).new(onSuccess, onError))
  end

  def subscribe(onSuccess : Proc(T, Nil), onComplete : Proc(Void), onError : Proc(Exception, Nil)) : Subscription
    return subscribeWith(LambdaMaybeObserver(T).new(onSuccess, onComplete, onError))
  end

  abstract def subscribeActual(observer)
end
