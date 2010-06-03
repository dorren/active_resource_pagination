class Hash
  # similar to Enumerable partition() method, separate one hash into 2 based on the passed in test condition.
  def partition(&block)
    h = dup
    h2 = {}
    each{|k, v| 
      h2[k] = h.delete(k) if block.call(k,v)  
    }
    [h2, h]
  end
end