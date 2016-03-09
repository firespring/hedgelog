class Hedgelog
  class Transformer
    def initialize(*transforms)
      @transforms = transforms
    end

    def transform(data)
      # Need to Marshal.dump/Marshal.load to deep copy the input so that scrubbing doesn't change global state
      d = Marshal.load(Marshal.dump(data))

      @transforms.reduce(d) do |input, transform|
        transform.transform(input)
      end
    end
  end
end
