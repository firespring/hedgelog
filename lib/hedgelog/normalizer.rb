class Hedgelog
  class Normalizer 
    def normalize(data)
      # Need to Marshal.dump/Marshal.load to deep copy the input so that scrubbing doesn't change global state
      d = Marshal.load(Marshal.dump(data))
      normalize_hash(d)
    end
  
    def normalize_struct(struct)
      return Hash[struct.each_pair.to_a]
    end

    def normalize_hash(hash)
      Hash[hash.map do |key, val|
        [key, normalize_thing(val)]
      end]
    end

    def normalize_array(array)
      array.map do |val|
        normalize_thing(val)
      end
    end

    private

    def normalize_thing(thing)
      return '' if thing.nil?
      return normalize_struct(thing) if thing.is_a?(Struct)
      return normalize_array(thing) if thing.is_a?(Array)
      return normalize_hash(thing) if thing.is_a?(Hash)
      return thing if thing.is_a?(String) || thing.is_a?(Float) || thing.is_a?(Fixnum)
      thing
    end
  end
end
