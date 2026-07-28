defmodule Folio.Native.GeneratedStubs do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def parse_markdown(_markdown) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def compile_pdf(_content, _styles, _files) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def compile_svg(_content, _styles, _files) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def compile_png(_content, _styles, _files, _dpi) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def register_file(_path, _data) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def unregister_file(_path) do
        :erlang.nif_error(:nif_not_loaded)
      end
    end
  end
end
