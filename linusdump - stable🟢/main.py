import discord
from discord.ext import commands
import subprocess
import os

TOKEN = os.getenv('DISCORD_TOKEN')  # Set your token as an environment variable

intents = discord.Intents.default()
bot = commands.Bot(command_prefix='.', intents=intents)

@bot.command()
async def linusdump(ctx):
    try:
        # Run the dumper (replace with actual command if needed)
        # Example: subprocess.run(['lune', 'main.luau'], ...)
        result = subprocess.run(['lune', 'main.luau'], capture_output=True, text=True, timeout=60)
        output = result.stdout.strip()
        if not output:
            await ctx.send(f'{ctx.author.mention} ni;l, output nill, reason No output from dumper')
        else:
            await ctx.send(f'{ctx.author.mention} Dump output:\n```{output[:1900]}```')
    except Exception as e:
        await ctx.send(f'{ctx.author.mention} ni;l, output nill, reason {str(e)}')

if __name__ == '__main__':
    if not TOKEN:
        print('DISCORD_TOKEN environment variable not set.')
    else:
        bot.run(TOKEN)
