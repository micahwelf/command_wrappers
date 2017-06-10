-- The main purpose of Command_Wrappers is to make native Linux commands
-- available to the command path of Windows 10 (With Linux Subsystem installed).

with Ada.Text_IO;
with Ada.Text_IO.Text_Streams; use Ada.Text_IO.Text_Streams;
with Ada.Characters.Latin_1;   use Ada.Characters.Latin_1;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Command_Line;         use Ada.Command_Line;
with Ada.Environment_Variables;
with GNAT.OS_Lib;

procedure zsh is
   package IO renames Ada.Text_IO;
   package OS renames GNAT.OS_Lib;
   package Env renames Ada.Environment_Variables;

   function Munge_Arguments return String is
      Last_Argument : Natural  := Argument_Count;
      Index         : Positive := 1;

      function Normalize (Source : String) return String is
         Last  : Natural  := Source'Last;
         Index : Positive := Source'First;
         function Get_Character (Index : Natural) return String is
         begin
            if Index > Last
            then
               return "";
            elsif Source (Index) = LF
            then
               return
                 (if Index = Last then ''' & LF & '''
                  else ''' & LF & ''' & Get_Character (Index + 1));
            else
               return
                 (if Index = Last then '\' & Source (Index)
                  else '\' & Source (Index) & Get_Character (Index + 1));
            end if;
         end Get_Character;
      begin
         return Get_Character (Index);
      end Normalize;

      function Munge_Arguments (Index : Positive) return String is
      begin
         if Index > Last_Argument
         then
            return "";
         elsif Index = Last_Argument
         then
            return Space & Normalize (Argument (Index));
         elsif Index < Last_Argument
         then
            return Space &
              Normalize (Argument (Index)) &
              String'(Munge_Arguments (Index + 1));
         end if;
         return "";
      end Munge_Arguments; -- Inner Munge.

   begin
      return Munge_Arguments (Index);
   end Munge_Arguments; -- Outer Munge.

   function "+" (Right : String) return OS.String_Access is
      Ret : OS.String_Access := new String'(Right);
   begin
      return Ret;
   end "+";
   New_Arguments : OS.Argument_List := (+"-c", +("zsh" & Munge_Arguments));
begin
   OS.Set_Errno
     (OS.Spawn
        (Env.Value ("SystemRoot", "C:\Windows") & "\System32" & "\bash.exe",
         New_Arguments));
end zsh;
