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
require "../../Single"
require "../../SingleSource"
require "../../SingleObserver"
require "../../Subscription"
require "../../subscriptions/CompositeSubscription"

private class SingleAmbObserver(T)
  include SingleObserver(T)

  def initialize(@observer : SingleObserver(T), @subscription : CompositeSubscription, @winner : Atomic(Int8))
  end

  def onSubscribe(sub : Subscription)
    @subscription.add(sub)
  end

  def onSuccess(x : T)
    if (@winner.compare_and_set(0, 1))
      begin
        @observer.onSuccess(x)
      ensure
        @subscription.cancel
      end
    end
  end

  def onError(e : Exception)
    if (@winner.compare_and_set(0, 1))
      begin
        @observer.onError(e)
      ensure
        @subscription.cancel
      end
    else
      raise(e)
    end
  end
end

# :nodoc:
class SingleAmbArray(T) < Single(T)
  def initialize(@sources : Array(SingleSource(T)))
  end

  def subscribeActual(observer : SingleObserver(T))
    winner = Atomic(Int8).new(0)
    subscription = CompositeSubscription.new

    observer.onSubscribe(subscription)

    @sources.each do |x|
      if (subscription.alive)
        x.subscribe(SingleAmbObserver(T).new(observer, subscription, winner))
      end
    end
  end
end