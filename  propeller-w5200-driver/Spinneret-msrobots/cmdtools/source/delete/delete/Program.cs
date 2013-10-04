using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace delete
{
    class Program
    {
        static void Main(string[] args)
        {
            int cnt = args.Length;
            if (cnt < 1)
            {
                Console.WriteLine("USAGE: delete remotepathfilename");
                Console.WriteLine("EXAMPLE: delete http://192.168.1.117/Test.txt");
            }
            else
            {
                Console.WriteLine(DeleteEntry(args[0]));
            }
            //Console.ReadKey();
        }

        private static string DeleteEntry(string remotepathfilename)
        {
            string sReturn = "";
            try
            {
                System.Net.HttpWebRequest request = (System.Net.HttpWebRequest)System.Net.WebRequest.Create(remotepathfilename);
                request.Method = "DELETE";
                System.Net.HttpWebResponse response = (System.Net.HttpWebResponse)request.GetResponse();
                sReturn = response.StatusCode.ToString();
                if (sReturn != response.StatusDescription)
                    sReturn += " " + response.StatusDescription;
                response.Close();
            }
            catch (Exception ex1)
            {
                sReturn = ex1.Message;
            }
            return sReturn;
        }
    }
}
