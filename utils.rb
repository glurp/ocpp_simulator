#################################################################################
# qq ouils
#################################################################################

class Hash
  def nearest(k)
    self.keys.map {|a| [k.to_s.dist(a),a] }.sort {|a,b| a[0]<=>b[0]}[0][1]
  end
  def nearest_merge(oh)
    a=self.dup
    a.size==0 ? a.merge(oh) :  oh.each { |k,v| a[k] ? a[k]=v : (a[n=nearest(k)]=v ; puts  "    merged #{k} with #{n} = #{v}" ) }
    a
  end
end
class String
  # extract daa parameters from a xml. htemplate describe 2 types of 
  # extraction :
  #   t:   <tag>DATA</tag>
  #   a:   <tag attribute="DATA"...>
  def extract_data(htemplate={})
     ret={}
     htemplate.each do |k,v| 
        type,name  = k.split(':') 
        value=case type
          when "a" then  self[/ #{name}=['"]([^'"]*)['"]/,1]
          when "t" then  self[/<(\w+:)?#{name}.*?>([^<]*)<\//,2]
          else
            "?"
        end
        ret[v]=value
     end
     ret
  end

  def dist(b) 
     ret=String.levenshtein_distance(self,b.to_s)
  end
  def self.levenshtein_distance(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m+1) {Array.new(n+1)}

    (0..m).each {|i| d[i][0] = i}
    (0..n).each {|j| d[0][j] = j}
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                    d[i-1][j-1]       # no operation required
                  else
                    [ d[i-1][j]+1,    # deletion
                      d[i][j-1]+1,    # insertion
                      d[i-1][j-1]+1,  # substitution
                    ].min
                  end
      end
    end
    d[m][n]
  end
  def showXmlData(txt="data :")
    puts "#{txt} << \n  "+self.scan(/<([^>]+)>([^<]+)<\//).map { |a| "%-30s %s" % [a.first.split(/\s+/).first,a.last.strip] }.join("\n  ")+"\n>>"
  end  
end