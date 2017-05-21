defmodule GoogleSearch do
  @moduledoc """
  Provides a function to search terms on Google
  """

  @url_home "https://www.google.com/"
  @url_search "https://www.google.com/search"

  @spec fetch_page(String.t) :: HTTPoison.Response.t

  def fetch_page(url) do
    headers = [
      "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0"
    ]
    HTTPoison.request(:get, url, "", headers, [{:follow_redirect, true}])
  end

  def get_cookies() do
    {_, response} = fetch_page(@url_home)
    IO.inspect response.headers
  end

  defp build_url(url, %{q: _term} = params) do
    "#{url}?" <> URI.encode_query(params)
  end

  @docp """
  List urls in Google's search results

  """
  defp list_urls(html) do
    html
    |> Floki.find("div.g h3.r > a")
    |> Enum.map(
      # first, when href is the first element of the list.
      #      fn
      #        {_, [{"href", href} | _xs], _} -> href
      #        {_, [ _ | [{"href", href} | _xs]], _} -> href
      #      end
      fn { _, attrs, _} -> Enum.find(attrs, &(match?({"href", _href}, &1))) |> elem(1) end
    )
  end

  defp process_stream_page(acc, body) do
    urls = list_urls(body)
    if Enum.empty?(urls) do
      {:halt, acc}
    else
      {urls, acc ++ urls}
    end
  end

  def search_stream(term, site \\ nil, num \\ 10, index \\ 0) do
    params = %{
      q: term,
      as_sitesearch: site,
      num: num,
      start: index
    }

    Stream.resource(fn -> [] end,
      fn acc ->
        s_index = index + length(acc)
        url = build_url(@url_search, %{params | :start => s_index})
        IO.puts(url)
        case fetch_page(url) do
          {:ok, %HTTPoison.Response{body: body}} -> process_stream_page(acc, body)
          {:error, _error} -> {:halt, acc}
        end
      end,
      fn _acc -> nil end
    )
  end

  # @spec search(String.t, String.t, int, int) :: list
  def search(term, site \\ nil, num \\ 10, index \\ 0) do
    url = build_url(@url_search, %{
      q: term,
      as_sitesearch: site,
      num: num,
      start: index
    })
    IO.puts url
    case fetch_page(url) do
      {:ok, %HTTPoison.Response{body: body}} -> {:ok, list_urls(body)}
      {:error, error} -> {:error, error}
    end
  end

end
