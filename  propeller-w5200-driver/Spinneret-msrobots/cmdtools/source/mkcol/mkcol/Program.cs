using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace mkcol
{
    class Program
    {
        static void Main(string[] args)
        {
            int cnt = args.Length;
            if (cnt < 1)
            {
                Console.WriteLine("USAGE: mkcol remotepathname");
                Console.WriteLine("EXAMPLE: mkcol http://192.168.1.117/upload/");
            }
            else
            {
                Console.WriteLine(MakeCollection(args[0]));
            }
            //Console.ReadKey();
        }

        private static string MakeCollection(string remotepathname)
        {
            string sReturn = "";
            try
            {
                System.Net.HttpWebRequest request = (System.Net.HttpWebRequest)System.Net.WebRequest.Create(remotepathname);
                request.Method = "MKCOL";
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
