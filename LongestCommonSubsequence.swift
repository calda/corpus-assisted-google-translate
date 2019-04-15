// from https://stackoverflow.com/questions/45524907/find-longest-common-substring-of-array-of-strings

class LongestCommon
{
    // Returns length of LCS for X[0..m-1], Y[0..n-1]
    private static func lcSubsequence(_ X : String  , _ Y : String  ) -> String
    {
        let m = X.count
        let n = Y.count
        
        var L = Array(repeating: Array(repeating: 0, count: n + 1 ) , count: m + 1)
        // Following steps build L[m+1][n+1] in bottom up fashion. Note
        // that L[i][j] contains length of LCS of X[0..i-1] and Y[0..j-1]
        for i in stride(from: 0, through: m, by: 1)
        {
            for j in stride(from: 0, through: n, by: 1)
            {
                if i == 0 || j == 0
                {
                    L[i][j] = 0;
                }
                else if X[X.index( X.startIndex , offsetBy: (i - 1) )] == Y[Y.index( Y.startIndex , offsetBy: (j - 1) )]
                {
                    L[i][j] = L[i-1][j-1] + 1
                }
                else
                {
                    L[i][j] = max(L[i-1][j], L[i][j-1])
                }
            }
            
        }
        
        // Following code is used to print LCS
        var index = L[m][n]
        // Create a character array to store the lcs string
        var lcs = ""
        // Start from the right-most-bottom-most corner and
        // one by one store characters in lcs[]
        var i = m
        var j = n
        
        while (i > 0 && j > 0)
        {
            // If current character in X[] and Y are same, then
            // current character is part of LCS
            if X[X.index( X.startIndex , offsetBy: (i - 1) )] == Y[Y.index( Y.startIndex , offsetBy: (j - 1) )]
            {
                lcs.append(X[X.index( X.startIndex , offsetBy: (i - 1) )])
                i-=1
                j-=1
                index-=1
            }
                // If not same, then find the larger of two and
                // go in the direction of larger value
            else if (L[i-1][j] > L[i][j-1])
            {
                i-=1
            }
            else
            {
                j-=1
            }
        }
        
        // return the lcs
        return String(lcs.reversed())
    }
    
    // Returns length of LCS for X[0..m-1], Y[0..n-1]
    private static func lcSubstring(_ X : String  , _ Y : String  ) -> String
    {
        let m = X.count
        let n = Y.count
        
        var L = Array(repeating: Array(repeating: 0, count: n + 1 ) , count: m + 1)
        var result : (length : Int, iEnd : Int, jEnd : Int) = (0,0,0)
        // Following steps build L[m+1][n+1] in bottom up fashion. Note
        // that L[i][j] contains length of LCS of X[0..i-1] and Y[0..j-1]
        for i in stride(from: 0, through: m, by: 1)
        {
            for j in stride(from: 0, through: n, by: 1)
            {
                if i == 0 || j == 0
                {
                    L[i][j] = 0;
                }
                else if X[X.index( X.startIndex , offsetBy: (i - 1) )] == Y[Y.index( Y.startIndex , offsetBy: (j - 1) )]
                {
                    L[i][j] = L[i-1][j-1] + 1
                    
                    if result.0 < L[i][j]
                    {
                        result.length = L[i][j]
                        result.iEnd = i
                        result.jEnd = j
                    }
                }
                else
                {
                    L[i][j] = 0 //max(L[i-1][j], L[i][j-1])
                }
            }
            
        }
        
        // Following code is used to print LCS
        
        
        let lcs = X[X.index(X.startIndex, offsetBy: result.iEnd-result.length)..<X.index(X.startIndex, offsetBy: result.iEnd)]
        
        // return the lcs
        return String(lcs)
    }
    
    // driver program
    
    class func subsequenceOf(_ strings : [String] ) -> String
    {
        var answer = strings[0] // For on string answer is itself
        
        for i in stride(from: 1, to: strings.count, by: 1)
        {
            answer = lcSubsequence(answer,strings[i])
        }
        return answer
    }
    
    class func substringOf(_ strings : [String] ) -> String
    {
        var answer = strings[0] // For on string answer is itself
        
        for i in stride(from: 1, to: strings.count, by: 1)
        {
            answer = lcSubstring(answer,strings[i])
        }
        return answer
    }
    
    
    
}
