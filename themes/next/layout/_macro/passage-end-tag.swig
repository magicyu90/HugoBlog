<div>
    {% if not is_index %}
        <div style="text-align:center;color: #ccc;font-size:14px;">-------------　　　　本文结束　<i class="fa fa-heart"></i>　感谢您的阅读　　　　-------------</div>
    {% endif %}
</div>


{% if theme.passage_end_tag.enabled %}
  <div>
 {# 表示如果不在索引列表中加入后续的HTML代码 #}
 {% if not is_index %}
    <ul class="post-copyright">
      <li class="post-copyright-author">
          <strong>本文作者：</strong>{{ theme.author }}
      </li>
      <li class="post-copyright-link">
        <strong>本文链接：</strong>
        <a href="{{ url_for(page.path) }}" title="{{ page.path }}">{{ page.path }}</a>
      </li>
      <li class="post-copyright-license">
        <strong>版权声明： </strong>
        本博客所有文章除特别声明外，均采用 <a href="http://creativecommons.org/licenses/by-nc-sa/3.0/cn/" rel="external nofollow" target="_blank">CC BY-NC-SA 3.0 CN</a> 许可协议。转载请注明出处！
      </li>
    </ul>
  {% endif %}
</div>
{% endif %}
